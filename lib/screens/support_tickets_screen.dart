import 'package:flutter/material.dart';
import '../services/support_ticket_service.dart';
import '../services/courier_session_service.dart';

const _ticketStatuses = {
  'new': 'Nouveau',
  'in_progress': 'En cours',
  'waiting_customer': 'En attente de votre réponse',
  'resolved': 'Résolu',
  'closed': 'Fermé'
};

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key, this.service, this.orderReference});
  final SupportTicketService? service;
  final String? orderReference;
  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsState();
}

class _SupportTicketsState extends State<SupportTicketsScreen> {
  late final service = widget.service ?? SupportTicketService();
  List<dynamic> rows = [];
  int? next;
  bool loading = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool more = false}) async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final d = await service.request('', page: more ? (next ?? 1) : 1);
      if (!mounted) return;
      setState(() {
        rows = more ? [...rows, ...d['data'] as List] : d['data'] as List;
        next = d['next_page'] as int?;
      });
    } catch (e) {
      if (mounted) setState(() => error = CourierSessionService.userMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> create() async {
    final id = await Navigator.push<int>(
        context,
        MaterialPageRoute(
            builder: (_) => _CreateTicket(
                service: service, reference: widget.orderReference)));
    if (!mounted || id == null) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                SupportTicketScreen(service: service, ticketId: id)));
    load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Support · Mes tickets')),
      body: RefreshIndicator(
          onRefresh: () => load(),
          child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                FilledButton.icon(
                    onPressed: create,
                    icon: const Icon(Icons.add),
                    label: const Text('Ouvrir un ticket')),
                if (widget.orderReference != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Commande ${widget.orderReference}')),
                if (error != null) Text(error!),
                if (loading) const LinearProgressIndicator(),
                if (!loading && error == null && rows.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Aucun ticket pour le moment.')),
                for (final row in rows)
                  Card(
                      child: ListTile(
                          title:
                              Text('${row['reference']} · ${row['subject']}'),
                          subtitle:
                              Text(_ticketStatuses[row['status']] ?? 'Ticket'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => SupportTicketScreen(
                                        service: service,
                                        ticketId: row['id'] as int)));
                            if (mounted) load();
                          })),
                if (next != null)
                  TextButton(
                      onPressed: loading ? null : () => load(more: true),
                      child: const Text('Voir plus')),
                if (error != null)
                  TextButton(
                      onPressed: () => load(), child: const Text('Réessayer')),
              ])));
}

class _CreateTicket extends StatefulWidget {
  const _CreateTicket({required this.service, this.reference});
  final SupportTicketService service;
  final String? reference;
  @override
  State<_CreateTicket> createState() => _CreateTicketState();
}

class _CreateTicketState extends State<_CreateTicket> {
  final form = GlobalKey<FormState>();
  final subject = TextEditingController();
  final body = TextEditingController();
  late final reference = TextEditingController(text: widget.reference);
  final keyRequest = SupportTicketService.requestKey();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    subject.dispose();
    body.dispose();
    reference.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final d = await widget.service.request('', body: {
        'subject': subject.text.trim(),
        'body': body.text.trim(),
        'category': 'delivery',
        'order_reference':
            reference.text.trim().isEmpty ? null : reference.text.trim(),
        'request_key': keyRequest
      });
      if (mounted) Navigator.pop(context, d['data']['id'] as int);
    } catch (e) {
      if (mounted) setState(() => error = CourierSessionService.userMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Ouvrir un ticket')),
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const Text(
                'Erreur de localisation ? Précisez la bonne adresse et un repère. Le Support examinera votre demande ; cela ne change pas automatiquement votre commande.'),
            const SizedBox(height: 16),
            TextFormField(
                controller: reference,
                decoration: const InputDecoration(
                    labelText: 'Référence commande (facultatif)'),
                maxLength: 100),
            TextFormField(
                controller: subject,
                decoration: const InputDecoration(labelText: 'Sujet'),
                maxLength: 180,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Indiquez le sujet' : null),
            TextFormField(
                controller: body,
                decoration: const InputDecoration(
                    labelText: 'Votre demande / bonne localisation'),
                minLines: 4,
                maxLines: 8,
                maxLength: 4000,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Décrivez votre demande'
                    : null),
            if (error != null) Text(error!),
            FilledButton(
                onPressed: busy ? null : send,
                child: Text(busy ? 'Envoi…' : 'Envoyer au Support')),
          ])));
}

class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen(
      {super.key, required this.service, required this.ticketId});
  final SupportTicketService service;
  final int ticketId;
  @override
  State<SupportTicketScreen> createState() => _TicketState();
}

class _TicketState extends State<SupportTicketScreen> {
  Map<String, dynamic>? ticket;
  List<dynamic> messages = [];
  int? next;
  bool loading = false, busy = false;
  String? error;
  final body = TextEditingController();
  String keyRequest = SupportTicketService.requestKey();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final d = await widget.service
          .request('/${widget.ticketId}', page: more ? (next ?? 1) : 1);
      if (!mounted) return;
      setState(() {
        ticket = Map<String, dynamic>.from(d['data']);
        messages = more
            ? [...d['messages'] as List, ...messages]
            : d['messages'] as List;
        next = d['next_page'] as int?;
      });
    } catch (e) {
      if (mounted) setState(() => error = CourierSessionService.userMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    if (busy || body.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.service.request('/${widget.ticketId}/messages',
          body: {'body': body.text.trim(), 'request_key': keyRequest});
      if (!mounted) return;
      body.clear();
      keyRequest = SupportTicketService.requestKey();
      await load();
    } catch (e) {
      if (mounted) setState(() => error = CourierSessionService.userMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(ticket?['reference'] ?? 'Ticket Support'),
          actions: [
            IconButton(
                onPressed: loading ? null : () => load(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser')
          ]),
      body: RefreshIndicator(
          onRefresh: () => load(),
          child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (ticket != null) ...[
                  Text(ticket!['subject'],
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(_ticketStatuses[ticket!['status']] ?? '')
                ],
                if (loading) const LinearProgressIndicator(),
                if (error != null) Text(error!),
                if (next != null)
                  TextButton(
                      onPressed: loading ? null : () => load(more: true),
                      child: const Text('Messages précédents')),
                for (final m in messages)
                  Card(
                      color: m['mine'] == true ? const Color(0xFFF3EBF9) : null,
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    m['mine'] == true
                                        ? 'Vous'
                                        : 'Support FlavorWay',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                SelectableText(m['body'] as String),
                                Text(
                                    (DateTime.tryParse(
                                                    m['created_at'].toString())
                                                ?.toLocal()
                                                .toString() ??
                                            '')
                                        .split('.')
                                        .first,
                                    style:
                                        Theme.of(context).textTheme.bodySmall)
                              ]))),
                if (ticket != null &&
                    !['resolved', 'closed'].contains(ticket!['status'])) ...[
                  TextField(
                      controller: body,
                      minLines: 2,
                      maxLines: 6,
                      maxLength: 4000,
                      decoration:
                          const InputDecoration(labelText: 'Votre réponse')),
                  FilledButton(
                      onPressed: busy ? null : send,
                      child: Text(busy ? 'Envoi…' : 'Envoyer'))
                ],
              ])));
}
