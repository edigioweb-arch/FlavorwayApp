import 'package:flutter/material.dart';
import '../../models/reservation_model.dart';
import '../../services/restaurant_workspace_service.dart';
import '../../services/api_client.dart';

class RestaurantReservationsScreen extends StatefulWidget {
  const RestaurantReservationsScreen({super.key, this.workspace});
  final RestaurantWorkspaceService? workspace;
  @override
  State<RestaurantReservationsScreen> createState() =>
      _RestaurantReservationsScreenState();
}

class _RestaurantReservationsScreenState
    extends State<RestaurantReservationsScreen> {
  RestaurantWorkspaceService get api =>
      widget.workspace ?? RestaurantWorkspaceService.instance;
  List<ReservationModel> reservations = [];
  bool loading = true, acting = false;
  int page = 1, lastPage = 1;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await api.fetchReservations(page: page);
      if (!mounted) return;
      setState(() {
        reservations = (response['data'] as List)
            .map((entry) =>
                ReservationModel.fromJson(Map<String, dynamic>.from(entry)))
            .toList();
        lastPage = response['meta']?['last_page'] ?? 1;
      });
    } catch (_) {
      if (mounted)
        setState(() => error = 'Impossible de charger les réservations.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> act(ReservationModel reservation, String action) async {
    if (acting) return;
    String? reason;
    if (action == 'reject') {
      final input = TextEditingController();
      reason = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Motif du refus'),
                  content: TextField(controller: input),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler')),
                    TextButton(
                        onPressed: () =>
                            Navigator.pop(context, input.text.trim()),
                        child: const Text('Valider'))
                  ]));
      if (!mounted || reason == null || reason.isEmpty) return;
    }
    setState(() => acting = true);
    try {
      await api.reservationAction(reservation.reservationNumber, action,
          reason: reason);
      if (mounted) await load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiException
                ? e.message
                : 'Action refusée. Rechargez la réservation.')));
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Réservations restaurant')),
      body: RefreshIndicator(
          onRefresh: load,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (error != null) ...[
              Text(error!),
              TextButton(onPressed: load, child: const Text('Réessayer'))
            ] else if (reservations.isEmpty)
              const Text('Aucune réservation.')
            else
              for (final reservation in reservations)
                Card(
                    child: ExpansionTile(
                  title: Text(reservation.reservationNumber),
                  subtitle: Text(
                      '${reservation.customerName} • ${reservation.reservationDate} ${reservation.reservationTime} • ${reservation.displayStatus}'),
                  children: [
                    ListTile(
                        title: Text('${reservation.partySize} personnes'),
                        subtitle: Text([
                          reservation.customerPhone ?? '',
                          reservation.notes,
                          reservation.specialRequests,
                          reservation.rejectionReason ?? ''
                        ].where((s) => s.isNotEmpty).join('\n'))),
                    Wrap(spacing: 8, children: [
                      if (reservation.status == 'pending') ...[
                        TextButton(
                            onPressed: acting
                                ? null
                                : () => act(reservation, 'confirm'),
                            child: const Text('Confirmer')),
                        TextButton(
                            onPressed: acting
                                ? null
                                : () => act(reservation, 'reject'),
                            child: const Text('Refuser')),
                      ],
                      if (reservation.status == 'confirmed') ...[
                        TextButton(
                            onPressed:
                                acting ? null : () => act(reservation, 'honor'),
                            child: const Text('Honorée')),
                        TextButton(
                            onPressed: acting
                                ? null
                                : () => act(reservation, 'no-show'),
                            child: const Text('Absent')),
                      ],
                    ]),
                  ],
                )),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(
                  onPressed: !loading && page > 1
                      ? () {
                          page--;
                          load();
                        }
                      : null,
                  child: const Text('Précédent')),
              Text('$page / $lastPage'),
              TextButton(
                  onPressed: !loading && page < lastPage
                      ? () {
                          page++;
                          load();
                        }
                      : null,
                  child: const Text('Suivant'))
            ]),
          ])));
}
