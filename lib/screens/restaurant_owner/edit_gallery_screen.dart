import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../services/restaurant_workspace_service.dart';

class EditGalleryScreen extends StatefulWidget {
  const EditGalleryScreen({super.key, this.workspace, this.picker});
  final ImagePicker? picker;
  final RestaurantWorkspaceService? workspace;

  @override
  State<EditGalleryScreen> createState() => _EditGalleryScreenState();
}

class _EditGalleryScreenState extends State<EditGalleryScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color background = Color(0xFFFAF8F6);

  RestaurantWorkspaceService get _workspace =>
      widget.workspace ?? RestaurantWorkspaceService.instance;
  late final ImagePicker _picker = widget.picker ?? ImagePicker();
  Map<String, dynamic>? _gallery;
  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _workspace.fetchGallery();
      if (!mounted) return;
      setState(() {
        _gallery = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      if (!mounted || files.isEmpty) return;
      final multipartFiles = await Future.wait(
        files
            .map((file) => http.MultipartFile.fromPath('gallery[]', file.path)),
      );

      final data = await _workspace.uploadGallery(
        galleryFiles: multipartFiles,
      );

      if (!mounted) return;
      setState(() => _gallery = data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galerie mise à jour avec succès.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _deleteImage(String path) async {
    setState(() => _uploading = true);
    try {
      final data = await _workspace.deleteGalleryImage(path);
      if (!mounted) return;
      setState(() => _gallery = data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image supprimée de la galerie.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryItems = ((_gallery?['gallery'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: violetFlavor),
        title: Text(
          'Photos et galerie',
          style: GoogleFonts.inter(
            color: violetFlavor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _panel(
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                        onPressed: _load, child: const Text('Réessayer')),
                  ],
                ),
              )
            else ...[
              _panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visuels du restaurant',
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez ici les photos réelles du restaurant et des plats visibles dans l’application.',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF6F7390), height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if ((_gallery?['logo_url'] ?? '').toString().isNotEmpty)
                          _mediaCard((_gallery?['logo_url'] ?? '').toString(),
                              'Logo actuel'),
                        if ((_gallery?['cover_url'] ?? '')
                            .toString()
                            .isNotEmpty)
                          _mediaCard((_gallery?['cover_url'] ?? '').toString(),
                              'Couverture'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Galerie plats & restaurant',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _uploading ? null : _uploadImages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeFlavor,
                            foregroundColor: Colors.white,
                          ),
                          icon: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                              _uploading ? 'Envoi...' : 'Ajouter des photos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (galleryItems.isEmpty)
                      Text(
                        'Aucune photo réelle enregistrée pour le moment.',
                        style:
                            GoogleFonts.inter(color: const Color(0xFF6F7390)),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: galleryItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                        itemBuilder: (context, index) {
                          final item = galleryItems[index];
                          final url = (item['url'] ?? '').toString();
                          final path = (item['path'] ?? '').toString();

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFECE6F6)),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                              child: Icon(
                                                  Icons.broken_image_outlined)),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: InkWell(
                                    onTap: _uploading
                                        ? null
                                        : () => _deleteImage(path),
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.92),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE6F6)),
      ),
      child: child,
    );
  }

  Widget _mediaCard(String url, String label) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              url,
              width: 160,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 160,
                height: 110,
                color: const Color(0xFFF5F1FB),
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
