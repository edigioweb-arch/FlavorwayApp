import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/reservation_model.dart';
import '../services/api_client.dart';
import '../services/restaurant_service.dart';
import '../services/reservation_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

  String _scope = 'upcoming';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReservationService.instance.fetchReservations(scope: _scope);
    });
  }

  Future<void> _refresh() {
    return ReservationService.instance.fetchReservations(scope: _scope);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: violetFlavor,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Réservations',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: violetFlavor,
            onPressed: () => _openCreateReservationSheet(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: ReservationService.instance,
        builder: (context, _) {
          final service = ReservationService.instance;
          final reservations = service.reservations;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    _scopeChip('À venir', 'upcoming'),
                    const SizedBox(width: 10),
                    _scopeChip('Historique', 'history'),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: Builder(
                    builder: (context) {
                      if (service.state == ReservationLoadState.loading &&
                          reservations.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (service.state == ReservationLoadState.error &&
                          reservations.isEmpty) {
                        return ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  children: [
                                    Text(
                                      service.errorMessage ??
                                          'Impossible de charger les réservations.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _refresh,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: orangeFlavor,
                                      ),
                                      child: const Text('Réessayer'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      if (reservations.isEmpty) {
                        return ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Text(
                                'Aucune réservation pour le moment',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reservations.length,
                        itemBuilder: (context, index) {
                          final reservation = reservations[index];

                          return _ReservationCard(
                            reservation: reservation,
                            onDetails: () =>
                                _showReservationDetails(context, reservation),
                            onCancel: reservation.isUpcoming
                                ? () => _showCancelDialog(context, reservation)
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateReservationSheet(context),
        backgroundColor: orangeFlavor,
        icon: const Icon(Icons.add),
        label: const Text('Réserver'),
      ),
    );
  }

  Widget _scopeChip(String label, String scope) {
    final isActive = _scope == scope;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() {
            _scope = scope;
          });
          await _refresh();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? violetFlavor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? violetFlavor : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : violetFlavor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateReservationSheet(BuildContext context) async {
    final restaurants = context.read<RestaurantService>().approvedRestaurants;
    if (restaurants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun restaurant disponible pour réserver.')),
      );
      return;
    }

    final restaurantId = ValueNotifier<String>(restaurants.first.id);
    final dateController = TextEditingController(text: '2026-08-18');
    final timeController = TextEditingController(text: '20:00');
    final guestsController = TextEditingController(text: '2');
    final notesController = TextEditingController();
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Créer une réservation',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: violetFlavor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<String>(
                      valueListenable: restaurantId,
                      builder: (context, value, _) {
                        return DropdownButtonFormField<String>(
                          value: value,
                          items: restaurants
                              .map((restaurant) => DropdownMenuItem<String>(
                                    value: restaurant.id,
                                    child: Text(restaurant.name),
                                  ))
                              .toList(growable: false),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              restaurantId.value = newValue;
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Restaurant',
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        hintText: 'YYYY-MM-DD',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Heure',
                        hintText: 'HH:MM',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: guestsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de personnes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                setModalState(() => submitting = true);
                                try {
                                  final created = await ReservationService.instance
                                      .createReservation(
                                    restaurantId:
                                        int.parse(restaurantId.value),
                                    reservationDate: dateController.text.trim(),
                                    reservationTime: timeController.text.trim(),
                                    partySize:
                                        int.tryParse(guestsController.text) ?? 0,
                                    notes: notesController.text,
                                  );

                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Réservation ${created.reservationNumber} créée.',
                                      ),
                                    ),
                                  );
                                } on ApiException catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    SnackBar(content: Text(error.message)),
                                  );
                                } finally {
                                  if (context.mounted) {
                                    setModalState(() => submitting = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeFlavor,
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirmer la réservation'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showReservationDetails(
    BuildContext context,
    ReservationModel reservation,
  ) async {
    final detail = await ReservationService.instance
            .fetchReservationDetail(reservation.reservationNumber) ??
        reservation;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Détail de réservation',
                style: GoogleFonts.poppins(
                  color: violetFlavor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _detailLine('Numéro', detail.reservationNumber),
              _detailLine('Restaurant', detail.restaurantName),
              _detailLine('Date', detail.reservationDate),
              _detailLine('Heure', detail.reservationTime),
              _detailLine('Personnes', '${detail.partySize}'),
              _detailLine('Statut', detail.displayStatus),
              if (detail.notes.isNotEmpty) _detailLine('Note', detail.notes),
              if ((detail.rejectionReason ?? '').isNotEmpty)
                _detailLine('Motif refus', detail.rejectionReason!),
              if ((detail.cancellationReason ?? '').isNotEmpty)
                _detailLine('Motif annulation', detail.cancellationReason!),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeFlavor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(90),
                    ),
                  ),
                  child: Text(
                    'Fermer',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: violetFlavor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, ReservationModel reservation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Annuler la réservation'),
          content: const Text(
            'Voulez-vous vraiment annuler cette réservation ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.maybePop(context);

                try {
                  await ReservationService.instance.cancelReservation(reservation);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Réservation annulée'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } on ApiException catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeFlavor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(90),
                ),
              ),
              child: const Text('Oui, annuler'),
            ),
          ],
        );
      },
    );
  }
}

class _ReservationCard extends StatelessWidget {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

  const _ReservationCard({
    required this.reservation,
    required this.onDetails,
    required this.onCancel,
  });

  final ReservationModel reservation;
  final VoidCallback onDetails;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (reservation.status) {
      'confirmed' => Colors.green,
      'pending' => Colors.orange,
      'rejected' => Colors.red,
      'honored' => Colors.teal,
      'no_show' => Colors.deepPurple,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reservation.restaurantName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: violetFlavor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  reservation.displayStatus,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${reservation.reservationDate} • ${reservation.reservationTime} • ${reservation.partySize} personnes',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reservation.reservationNumber,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetails,
                  child: const Text('Détails'),
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeFlavor,
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
