import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color greenSuccess = Color(0xFF4CAF50);
  static const Color screenBackground = Color(0xFFF3F0FA);

  final String restaurantName = 'Joli Coin';
  final String courierName = 'Jean M.';
  final String courierVehicle = 'Peugeot 206';
  final String courierPhone = '+242 06 00 00 00';

  int currentStep = 0;
  final List<Timer> _timers = [];

  final List<_TrackingStep> steps = const [
    _TrackingStep(
      title: 'Commande reçue',
      time: '15:00',
      managedBy: 'Restaurant',
    ),
    _TrackingStep(
      title: 'En préparation',
      time: '15:12',
      managedBy: 'Restaurant',
    ),
    _TrackingStep(
      title: 'Coursier a récupéré la commande',
      time: '15:28',
      managedBy: 'Livreur',
    ),
    _TrackingStep(
      title: 'En route',
      time: '15:35',
      managedBy: 'Livreur',
    ),
    _TrackingStep(
      title: 'Livré',
      time: '15:48',
      managedBy: 'Livreur',
    ),
  ];

  double get progressValue {
    if (steps.length <= 1) return 0;
    return currentStep / (steps.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _startTrackingDemo();
  }

  void _startTrackingDemo() {
    _timers.add(
      Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => currentStep = 1);
      }),
    );
    _timers.add(
      Timer(const Duration(seconds: 6), () {
        if (mounted) setState(() => currentStep = 2);
      }),
    );
    _timers.add(
      Timer(const Duration(seconds: 9), () {
        if (mounted) setState(() => currentStep = 3);
      }),
    );
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = steps[currentStep];

    return Scaffold(
      backgroundColor: screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTrackingSummary(current),
                    const SizedBox(height: 18),
                    _buildActionButtons(),
                    const SizedBox(height: 18),
                    _buildTimeline(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              '#CMD1245 - Livraison',
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

  Widget _buildTrackingSummary(_TrackingStep current) {
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
                        'Restaurant: $restaurantName\nCoursier: $courierName • $courierVehicle',
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
                        'ETA: 12 min',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '12:45',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Mis à jour à ${current.time}',
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showMessageSheet,
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
              onPressed: _showCallSheet,
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

  Widget _buildTimeline() {
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
          final isValidated = index <= currentStep;
          final isLast = index == steps.length - 1;

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
                              color: index < currentStep
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
                          step.title,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1F1F1F),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isValidated ? step.time : 'En attente',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isValidated
                              ? 'Étape validée par ${step.managedBy.toLowerCase()}'
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

  void _showMessageSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatScreen(
          conversationId: 'courier_jean_m',
        ),
      ),
    );
  }

  void _showCallSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  child: Icon(Icons.phone_rounded, color: Colors.white),
                ),
                title: Text(courierName),
                subtitle: Text(courierPhone),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.maybePop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appel vers $courierPhone'),
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
  }
}

class _TrackingStep {
  final String title;
  final String time;
  final String managedBy;

  const _TrackingStep({
    required this.title,
    required this.time,
    required this.managedBy,
  });
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
