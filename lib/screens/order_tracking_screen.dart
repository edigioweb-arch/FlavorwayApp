import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import '../services/order_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color greenSuccess = Color(0xFF4CAF50);
  static const Color screenBackground = Color(0xFFF3F0FA);

  Stream<OrderModel?>? _orderStream;

  @override
  void initState() {
    super.initState();
    _orderStream = OrderService.instance.orderStream(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      body: SafeArea(
        child: StreamBuilder<OrderModel?>(
          stream: _orderStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final order = snapshot.data;
            if (order == null) {
              return const Center(
                child: Text('Commande introuvable'),
              );
            }

            final currentStep = order.lastTimelineStep;
            final steps = order.timeline;
            final progressValue = steps.isEmpty
                ? 0.0
                : ((steps.indexWhere((s) => s.status == order.status) + 1) /
                        steps.length)
                    .clamp(0.0, 1.0);

            return Column(
              children: [
                _buildHeader(context, order),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTrackingSummary(
                            order, currentStep, progressValue),
                        const SizedBox(height: 18),
                        _buildActionButtons(order),
                        const SizedBox(height: 18),
                        _buildTimeline(order, steps),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, OrderModel order) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF263238),
              size: 28,
            ),
          ),
          Expanded(
            child: Text(
              '#${order.orderId} - Livraison',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF263238),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTrackingSummary(
      OrderModel order, TimelineStep current, double progressValue) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: greenSuccess.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: greenSuccess,
                    size: 42,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FlavorWay\nDelivery in progress',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1F1F1F),
                          fontSize: 17,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Restaurant: ${order.restaurantName}${order.courierName.isNotEmpty ? '\nCoursier: ${order.courierName}${order.courierVehicle.isNotEmpty ? ' • ${order.courierVehicle}' : ''}' : ''}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: orangeFlavor,
                        borderRadius: BorderRadius.circular(90),
                      ),
                      child: Text(
                        order.status,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _formatTime(current.timestamp),
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Mis à jour à ${_formatTime(current.timestamp)}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    height: 9,
                    color: Colors.grey.shade200,
                  ),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    widthFactor: progressValue.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 9,
                      decoration: BoxDecoration(
                        color: greenSuccess,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(22),
            ),
            child: SizedBox(
              height: 60,
              width: double.infinity,
              child: CustomPaint(
                painter: _MiniMapPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatScreen(
                      conversationId: 'courier_jean_m',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: violetFlavor,
                side: const BorderSide(color: violetFlavor),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(90),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appeler le coursier',
                            style: GoogleFonts.poppins(
                              color: violetFlavor,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: greenSuccess,
                              child: Icon(Icons.phone_rounded,
                                  color: Colors.white),
                            ),
                            title: Text(order.courierName.isNotEmpty
                                ? order.courierName
                                : 'Non assigné'),
                            subtitle: Text(order.courierPhone.isNotEmpty
                                ? order.courierPhone
                                : 'Non disponible'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.maybePop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(order.courierPhone.isNotEmpty
                                      ? 'Appel vers ${order.courierPhone}'
                                      : 'Aucun numéro disponible'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.phone_rounded),
              label: const Text('Appeler'),
              style: OutlinedButton.styleFrom(
                foregroundColor: violetFlavor,
                side: const BorderSide(color: violetFlavor),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(90),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(OrderModel order, List<TimelineStep> steps) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }

    final latestStatus = order.status;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;
          final isValidated =
              steps.indexWhere((s) => s.status == latestStatus) >= index;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 54,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isValidated
                              ? greenSuccess
                              : const Color(0xFFECECEF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isValidated
                                ? Colors.white
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: isValidated
                              ? [
                                  BoxShadow(
                                    color: greenSuccess.withOpacity(0.24),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          isValidated
                              ? Icons.check_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isValidated ? Colors.white : Colors.grey,
                          size: 24,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 3,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: index <
                                      steps.indexWhere(
                                          (s) => s.status == latestStatus)
                                  ? greenSuccess.withOpacity(0.75)
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 18),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.status,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1F1F1F),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isValidated
                              ? _formatTime(step.timestamp)
                              : 'En attente',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isValidated
                              ? 'Étape validée par ${step.updatedBy.toLowerCase()}'
                              : 'Non validée',
                          style: GoogleFonts.poppins(
                            color: isValidated ? greenSuccess : Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFE7E8EC);
    canvas.drawRect(Offset.zero & size, background);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final secondaryRoad = Paint()
      ..color = const Color(0xFFD0D3DA)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(-10, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.15,
        size.width + 10,
        size.height * 0.55,
      );
    canvas.drawPath(path1, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.15, -5)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.46,
        size.width * 0.18,
        size.height + 5,
      );
    canvas.drawPath(path2, secondaryRoad);

    final marker = Paint()..color = const Color(0xFF4B1F5C);
    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 0.42),
      7,
      marker,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
