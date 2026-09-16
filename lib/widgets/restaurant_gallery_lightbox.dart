import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Vignette et visionneuse utilisent la même liste d'images du restaurant.
class RestaurantGalleryThumbnail extends StatelessWidget {
  const RestaurantGalleryThumbnail(
      {super.key,
      required this.images,
      required this.index,
      required this.child});
  final List<String> images;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: 'Agrandir la photo ${index + 1}',
      child: InkWell(
        mouseCursor: SystemMouseCursors.zoomIn,
        onTap: () => showDialog<void>(
          context: context,
          barrierColor: Colors.black87,
          builder: (_) =>
              RestaurantGalleryLightbox(images: images, initialIndex: index),
        ),
        child: child,
      ),
    );
  }
}

class RestaurantGalleryLightbox extends StatefulWidget {
  const RestaurantGalleryLightbox(
      {super.key, required this.images, this.initialIndex = 0});
  final List<String> images;
  final int initialIndex;

  @override
  State<RestaurantGalleryLightbox> createState() =>
      _RestaurantGalleryLightboxState();
}

class _RestaurantGalleryLightboxState extends State<RestaurantGalleryLightbox> {
  late int _index = widget.images.isEmpty
      ? 0
      : widget.initialIndex.clamp(0, widget.images.length - 1);

  void _move(int delta) {
    if (widget.images.length < 2) return;
    setState(() => _index = (_index + delta) % widget.images.length);
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _close,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _move(-1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _move(1),
        },
        child: Focus(
            autofocus: true,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                  child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: Column(children: [
                  Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        tooltip: 'Fermer',
                        onPressed: _close,
                        icon: const Icon(Icons.close, color: Colors.white),
                      )),
                  Expanded(
                      child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: widget.images.isEmpty
                        ? const Center(
                            child: Text('Aucune photo',
                                style: TextStyle(color: Colors.white)))
                        : GestureDetector(
                            onTap: () {},
                            child:
                                Center(child: _image(widget.images[_index]))),
                  )),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(
                        tooltip: 'Photo précédente',
                        onPressed:
                            widget.images.length > 1 ? () => _move(-1) : null,
                        disabledColor: Colors.white38,
                        color: Colors.white,
                        icon: const Icon(Icons.chevron_left)),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                            '${widget.images.isEmpty ? 0 : _index + 1} / ${widget.images.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16))),
                    IconButton(
                        tooltip: 'Photo suivante',
                        onPressed:
                            widget.images.length > 1 ? () => _move(1) : null,
                        disabledColor: Colors.white38,
                        color: Colors.white,
                        icon: const Icon(Icons.chevron_right)),
                  ]),
                  const SizedBox(height: 12),
                ]),
              )),
            )),
      );

  Widget _image(String url) {
    Widget error(BuildContext context, Object error, StackTrace? stack) =>
        const Center(
            child: Text('Image indisponible',
                style: TextStyle(color: Colors.white)));
    return url.startsWith('http://') || url.startsWith('https://')
        ? Image.network(url,
            key: ValueKey(url), fit: BoxFit.contain, errorBuilder: error)
        : Image.asset(url,
            key: ValueKey(url), fit: BoxFit.contain, errorBuilder: error);
  }
}
