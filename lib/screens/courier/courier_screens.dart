import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/courier_session_service.dart';
import '../../services/notification_navigation_service.dart';

const _purple = Color(0xFF4B1F5C);
String _money(dynamic value) =>
    '${(num.tryParse('$value') ?? 0).toStringAsFixed(0)} FCFA';
String _label(dynamic value) =>
    const {
      'confirmed': 'Confirmée',
      'preparing': 'En préparation',
      'ready': 'Prête',
      'picked_up': 'Récupérée',
      'on_the_way': 'En livraison',
      'delivered': 'Livrée',
      'cancelled': 'Annulée',
      'payment_failed': 'Paiement échoué',
      'paid': 'Payé',
      'pending': 'En attente',
      'unpaid': 'À encaisser',
      'failed': 'Échoué',
      'cash': 'Paiement à la livraison',
      'restaurant': 'Restaurant',
      'flavorway': 'FlavorWay',
      'active': 'Actif',
      'reconciliation_required': 'Vérification financière nécessaire',
    }[value] ??
    '$value';
String _date(dynamic value) {
  final date = DateTime.tryParse('$value')?.toLocal();
  if (date == null) return '';
  return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

/// Every courier route, including notification links, passes through this gate.
class CourierGate extends StatelessWidget {
  const CourierGate({super.key, this.orderReference, this.session});
  final String? orderReference;
  final CourierSessionService? session;
  @override
  Widget build(BuildContext context) {
    final auth = session ?? CourierSessionService.instance;
    return AnimatedBuilder(
        animation: auth,
        builder: (context, _) {
          if (auth.restoreError != null) {
            return Scaffold(
                appBar: AppBar(title: const Text('Espace livreur')),
                body: _ErrorState(auth.restoreError!, auth.restore));
          }
          if (!auth.hasSession) return CourierLoginScreen(session: auth);
          if (auth.mustChangePassword) {
            return CourierPasswordScreen(session: auth);
          }
          if (orderReference != null) {
            return CourierOrderScreen(
                reference: orderReference!, session: auth);
          }
          return CourierDashboardScreen(session: auth);
        });
  }
}

class CourierLoginScreen extends StatefulWidget {
  const CourierLoginScreen({super.key, required this.session});
  final CourierSessionService session;
  @override
  State<CourierLoginScreen> createState() => _CourierLoginState();
}

class _CourierLoginState extends State<CourierLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.login(_email.text, _password.text);
    } catch (e) {
      if (mounted) {
        setState(() => _error = CourierSessionService.userMessage(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon,
      {bool password = false}) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Color(0xFF66616B)),
      prefixIcon: Icon(icon, color: Colors.grey),
      suffixIcon: password
          ? IconButton(
              tooltip: _obscurePassword
                  ? 'Afficher le mot de passe'
                  : 'Masquer le mot de passe',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility),
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFF36A2D), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _purple,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (Navigator.canPop(context))
                        IconButton(
                          tooltip: 'Retour',
                          onPressed:
                              _busy ? null : () => Navigator.maybePop(context),
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      const SizedBox(height: 20),
                      Center(
                          child: Column(children: [
                        ClipOval(
                            child: Image.asset('assets/images/logo.jpeg',
                                width: 120, height: 120, fit: BoxFit.cover)),
                        const SizedBox(height: 15),
                        const Text('FlavorWay',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF36A2D))),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delivery_dining,
                                    color: Color(0xFFF36A2D), size: 22),
                                SizedBox(width: 8),
                                Flexible(
                                    child: Text('Connexion livreur',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600))),
                              ]),
                        ),
                      ])),
                      const SizedBox(height: 32),
                      const Text('Bon retour !',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text(
                          'Connectez-vous pour retrouver vos livraisons.',
                          style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.white70)),
                      const SizedBox(height: 26),
                      TextField(
                        controller: _email,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        style: const TextStyle(color: Color(0xFF302936)),
                        decoration: _decoration('Email', Icons.person_outline),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: _obscurePassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        style: const TextStyle(color: Color(0xFF302936)),
                        decoration: _decoration(
                            'Mot de passe', Icons.lock_outline,
                            password: true),
                        onSubmitted: (_) => _login(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          CourierForgotPasswordScreen(
                                              session: widget.session,
                                              email: _email.text))),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white),
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ),
                      if (_error != null) ...[
                        Semantics(
                            liveRegion: true,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0EB),
                                  borderRadius: BorderRadius.circular(16)),
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: Color(0xFF922F19))),
                            )),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF36A2D),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFBA5225),
                            minimumSize: const Size.fromHeight(55),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: _busy ? null : _login,
                          child: _busy
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                      semanticsLabel: 'Connexion en cours'))
                              : const Text('Se connecter',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                          child: Text(
                        'Votre compte est créé par l’administration FlavorWay.\nPour vos accès, contactez votre administrateur.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, height: 1.6, color: Colors.white70),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class CourierForgotPasswordScreen extends StatefulWidget {
  const CourierForgotPasswordScreen(
      {super.key, required this.session, this.email = ''});
  final CourierSessionService session;
  final String email;
  @override
  State<CourierForgotPasswordScreen> createState() =>
      _CourierForgotPasswordState();
}

class _CourierForgotPasswordState extends State<CourierForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.email);
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _message;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await widget.session.requestPasswordReset(_email.text);
      if (mounted) setState(() => _message = message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = CourierSessionService.userMessage(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF4B1F5C),
        appBar: AppBar(
            backgroundColor: const Color(0xFF4B1F5C),
            foregroundColor: Colors.white,
            title: const Text('Retrouver mes accès')),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _form,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                          child: ClipOval(
                              child: Image.asset('assets/images/logo.jpeg',
                                  width: 100, height: 100))),
                      const SizedBox(height: 28),
                      const Text('Mot de passe oublié ?',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (_message == null) ...[
                        const Text(
                            'Indiquez l’email de votre compte livreur. L’administration recevra votre demande et pourra réinitialiser vos accès après vérification de votre identité.',
                            style:
                                TextStyle(color: Colors.white70, height: 1.6)),
                        const SizedBox(height: 24),
                        TextFormField(
                            controller: _email,
                            enabled: !_busy,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            style: const TextStyle(color: Color(0xFF302936)),
                            validator: (value) => value == null ||
                                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(value.trim())
                                ? 'Indiquez un email valide.'
                                : null,
                            decoration: InputDecoration(
                                hintText: 'Email',
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none))),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(_error!,
                                  style: const TextStyle(color: Colors.white))),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: _busy ? null : _send,
                            style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF36A2D),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(55)),
                            child: Text(_busy
                                ? 'Envoi en cours…'
                                : 'Envoyer ma demande')),
                      ] else ...[
                        Semantics(
                            liveRegion: true,
                            child: Text(_message!,
                                style: const TextStyle(
                                    color: Colors.white, height: 1.6))),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Retour à la connexion')),
                      ],
                    ]),
              )),
        ))),
      );
}

class CourierPasswordScreen extends StatefulWidget {
  const CourierPasswordScreen(
      {super.key, required this.session, this.mandatory = true});
  final bool mandatory;
  final CourierSessionService session;
  @override
  State<CourierPasswordScreen> createState() => _CourierPasswordState();
}

class _CourierPasswordState extends State<CourierPasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session
          .changePassword(_current.text, _next.text, _confirmation.text);
      if (mounted && !widget.mandatory) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = CourierSessionService.userMessage(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !widget.mandatory && !_busy,
      child: Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: !widget.mandatory,
            title: const Text('Changer mon mot de passe')),
        bottomNavigationBar: widget.mandatory
            ? null
            : _pageMenu(context, widget.session, 3, busy: _busy),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          Text(widget.mandatory
              ? 'Ce changement est obligatoire avant d’accéder aux livraisons. Au moins 12 caractères, avec lettres et chiffres.'
              : 'Choisissez au moins 12 caractères, avec lettres et chiffres.'),
          TextField(
              controller: _current,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Mot de passe actuel')),
          TextField(
              controller: _next,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Nouveau mot de passe')),
          TextField(
              controller: _confirmation,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe')),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Enregistrement…' : 'Enregistrer')),
          TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      try {
                        await widget.session.logout();
                      } catch (e) {
                        if (mounted) {
                          setState(() =>
                              _error = CourierSessionService.userMessage(e));
                        }
                      }
                    },
              child: const Text('Se déconnecter')),
        ]),
      ));
}

class CourierDashboardScreen extends StatefulWidget {
  const CourierDashboardScreen(
      {super.key, required this.session, this.initialTab = 0});
  final int initialTab;
  final CourierSessionService session;
  @override
  State<CourierDashboardScreen> createState() => _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboardScreen> {
  late int _tab = widget.initialTab;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text([
              'Espace livreur',
              'Commandes assignées',
              'Historique',
              'Profil livreur'
            ][_tab]),
            actions: [
              IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => _ProtectedCourierPage(
                            session: widget.session,
                            child: CourierNotificationsScreen(
                                session: widget.session))));
                  })
            ]),
        body: switch (_tab) {
          0 => _CourierDashboardData(
              session: widget.session,
              openOrders: () => setState(() => _tab = 1)),
          1 => CourierOrdersScreen(
              key: const ValueKey('active'), session: widget.session),
          2 => CourierOrdersScreen(
              key: const ValueKey('history'),
              session: widget.session,
              history: true),
          _ => CourierProfileScreen(session: widget.session),
        },
        bottomNavigationBar: _CourierMenu(
            selected: _tab, onSelected: (i) => setState(() => _tab = i)),
      );
}

class _CourierMenu extends StatelessWidget {
  const _CourierMenu({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: onSelected,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFEADFF0),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined), label: 'Accueil'),
            NavigationDestination(
                icon: Icon(Icons.delivery_dining), label: 'Commandes'),
            NavigationDestination(
                icon: Icon(Icons.history), label: 'Historique'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Profil'),
          ]);
}

Widget _pageMenu(
        BuildContext context, CourierSessionService session, int selected,
        {bool busy = false}) =>
    _CourierMenu(
        selected: selected,
        onSelected: (index) {
          if (busy) return;
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => _ProtectedCourierPage(
                      session: session,
                      child: CourierDashboardScreen(
                          session: session, initialTab: index))),
              (route) => route.isFirst);
        });

Widget _section(String title, List<Widget> children,
        {Color color = Colors.white}) =>
    Card(
        color: color,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFEAE4ED))),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _purple)),
                  const SizedBox(height: 10),
                  ...children
                ])));

class _ProtectedCourierPage extends StatelessWidget {
  const _ProtectedCourierPage({required this.session, required this.child});
  final CourierSessionService session;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: session,
      builder: (_, __) =>
          session.isReady ? child : CourierGate(session: session));
}

class _CourierDashboardData extends StatelessWidget {
  const _CourierDashboardData(
      {required this.session, required this.openOrders});
  final CourierSessionService session;
  final VoidCallback openOrders;
  @override
  Widget build(BuildContext context) => _RemoteData(
      session: session,
      path: 'dashboard',
      builder: (context, response, reload) {
        final data = response['data'] as Map;
        final profile = session.profile!;
        return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                      'Bonjour ${(profile['name']?.toString().trim().isNotEmpty ?? false) ? profile['name'] : [
                          profile['first_name'],
                          profile['last_name']
                        ].where((v) => v != null && '$v'.trim().isNotEmpty).join(' ')}',
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text('Livreur ${_label(profile['courier_type'])}'),
                  if (profile['restaurant'] is Map)
                    Text('${profile['restaurant']['name']}'),
                  const SizedBox(height: 20),
                  for (final stat in [
                    (
                      'Commandes actives',
                      '${data['active_orders'] ?? 0}',
                      Icons.delivery_dining,
                      const Color(0xFFEEE5F4),
                      _purple
                    ),
                    (
                      'Assignées aujourd’hui',
                      '${data['today_orders'] ?? 0}',
                      Icons.today_outlined,
                      const Color(0xFFE8F1FB),
                      const Color(0xFF225C94)
                    ),
                    (
                      'Livraisons terminées',
                      '${data['completed_deliveries'] ?? 0}',
                      Icons.check_circle_outline,
                      const Color(0xFFE5F3EB),
                      const Color(0xFF256A47)
                    ),
                    (
                      'Cash à encaisser',
                      _money(data['cash_due']),
                      Icons.payments_outlined,
                      const Color(0xFFFFEFDF),
                      const Color(0xFF99510D)
                    ),
                  ])
                    Card(
                        color: stat.$4,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(children: [
                              Icon(stat.$3, color: stat.$5, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(stat.$1,
                                        style: TextStyle(color: stat.$5)),
                                    const SizedBox(height: 5),
                                    Text(stat.$2,
                                        style: TextStyle(
                                            color: stat.$5,
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold)),
                                  ])),
                            ]))),
                  FilledButton(
                      onPressed: openOrders,
                      child: const Text('Voir mes commandes assignées')),
                ]));
      });
}

class CourierOrdersScreen extends StatefulWidget {
  const CourierOrdersScreen(
      {super.key, required this.session, this.history = false});
  final CourierSessionService session;
  final bool history;
  @override
  State<CourierOrdersScreen> createState() => _CourierOrdersState();
}

class _CourierOrdersState extends State<CourierOrdersScreen> {
  int _page = 1;
  int _reload = 0;
  @override
  Widget build(BuildContext context) => _RemoteData(
      key: ValueKey('$_page-$_reload'),
      session: widget.session,
      path: widget.history ? 'history' : 'orders',
      query: {'page': '$_page'},
      builder: (context, response, reload) {
        final orders = (response['data'] as List).cast<Map>();
        final meta = response['meta'] as Map? ?? {};
        return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (orders.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Aucune commande à afficher.')),
                  for (final order in orders)
                    Card(
                        child: ListTile(
                      title: Text('${order['order_number']}'),
                      subtitle: Text(
                          '${order['restaurant']?['name'] ?? ''}\n${_label(order['status'])} · ${_money(order['total'])}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => CourierGate(
                                session: widget.session,
                                orderReference: '${order['order_number']}')));
                        if (mounted) setState(() => _reload++);
                      },
                    )),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                            onPressed: _page > 1
                                ? () => setState(() => _page--)
                                : null,
                            child: const Text('Précédent')),
                        Text('Page $_page'),
                        TextButton(
                            onPressed: _page < (meta['last_page'] as num? ?? 1)
                                ? () => setState(() => _page++)
                                : null,
                            child: const Text('Suivant')),
                      ]),
                ]));
      });
}

class CourierOrderScreen extends StatefulWidget {
  const CourierOrderScreen(
      {super.key, required this.reference, required this.session});
  final String reference;
  final CourierSessionService session;
  @override
  State<CourierOrderScreen> createState() => _CourierOrderState();
}

class _CourierOrderState extends State<CourierOrderScreen> {
  bool _busy = false;
  String? _error;
  Future<void> _act(String action, Future<void> Function() reload) async {
    if (_busy) return;
    if (action == 'cash-collected') {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Confirmer l’encaissement'),
                  content: const Text(
                      'Confirmez uniquement après avoir reçu la totalité du Cash affiché.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Cash reçu'))
                  ]));
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.request(
          'orders/${Uri.encodeComponent(widget.reference)}/$action',
          body: {});
      await reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Confirmation enregistrée.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = CourierSessionService.userMessage(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFFF8F5FA),
      appBar: AppBar(title: Text(widget.reference)),
      bottomNavigationBar: _pageMenu(context, widget.session, 1, busy: _busy),
      body: _RemoteData(
          session: widget.session,
          path: 'orders/${Uri.encodeComponent(widget.reference)}',
          refreshInterval: const Duration(seconds: 10),
          builder: (context, response, reload) {
            final order = response['data'] as Map;
            final restaurant = order['restaurant'] as Map? ?? {};
            final address = order['delivery_address'] as Map? ?? {};
            final items = order['items'] as List? ?? [];
            final timeline = order['status_history'] as List? ?? [];
            final actions =
                (order['courier_actions'] as List? ?? []).whereType<String>();
            return RefreshIndicator(
                onRefresh: reload,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(_label(order['status']),
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      if (['confirmed', 'preparing'].contains(order['status']))
                        _section(
                            'En attente du restaurant',
                            [
                              Text(order['status'] == 'preparing'
                                  ? 'Le restaurant prépare la commande. Vous pourrez confirmer la récupération dès qu’il la déclarera prête.'
                                  : 'La commande vous est assignée. Le restaurant doit la préparer puis la déclarer prête avant votre récupération.'),
                              const SizedBox(height: 8),
                              const Text(
                                  'Le suivi se met à jour automatiquement.'),
                            ],
                            color: const Color(0xFFFFF1E3)),
                      if (['picked_up', 'on_the_way', 'delivered']
                          .contains(order['status']))
                        _section(
                            'Récupération confirmée',
                            [
                              const Row(children: [
                                Icon(Icons.check_circle,
                                    color: Color(0xFF256A47)),
                                SizedBox(width: 8),
                                Expanded(
                                    child: Text('Commande récupérée',
                                        style: TextStyle(
                                            color: Color(0xFF256A47))))
                              ])
                            ],
                            color: const Color(0xFFE5F3EB)),
                      if (_error != null)
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final action in actions)
                          FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: action == 'pickup'
                                      ? const Color(0xFFB3261E)
                                      : _purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12)),
                              onPressed:
                                  _busy ? null : () => _act(action, reload),
                              child: Text(const {
                                    'pickup': 'Confirmer la récupération',
                                    'on-the-way': 'Démarrer la livraison',
                                    'deliver': 'Confirmer la livraison',
                                  }[action] ??
                                  action)),
                        if (order['can_collect_cash'] == true)
                          FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => _act('cash-collected', reload),
                              child: const Text('Confirmer l’encaissement')),
                      ]),
                      if (_busy) const LinearProgressIndicator(),
                      const SizedBox(height: 20),
                      Text('Suivi de la commande',
                          style: Theme.of(context).textTheme.titleMedium),
                      if (timeline.isEmpty)
                        const Text('Aucun événement enregistré.'),
                      for (final event in timeline)
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(event['source'] == 'assignment'
                                ? 'Assignation livreur'
                                : _label(event['to_status'])),
                            subtitle: Text(_date(event['changed_at']))),
                      const SizedBox(height: 16),
                      _section('Retrait au restaurant', [
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.restaurant),
                            title: Text('${restaurant['name'] ?? ''}'),
                            subtitle: Text(
                                '${restaurant['address'] ?? 'Adresse restaurant non renseignée'}'))
                      ]),
                      _section('Livraison au client', [
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.location_on_outlined),
                            title: const Text('Adresse client'),
                            subtitle: Text([
                              address['address_line'] ?? address['address'],
                              address['city'],
                              address['delivery_zone_area_name'],
                            ]
                                .where((e) => e != null && '$e'.isNotEmpty)
                                .join(', ')))
                      ]),
                      _section('Articles à livrer', [
                        for (final item in items)
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              title:
                                  Text('${item['quantity']} × ${item['name']}'),
                              trailing: Text(_money(item['line_total'])),
                              subtitle: Text((item['options'] as List? ?? [])
                                  .map((o) =>
                                      '${o['option_name']} : ${o['option_value']}')
                                  .join('\n'))),
                      ]),
                      _section('Montant de la commande', [
                        for (final entry in {
                          'Sous-total': order['subtotal'],
                          'Frais de livraison': order['delivery_fee'],
                          'Remise': order['discount_total'],
                          'Total commande': order['total']
                        }.entries)
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(entry.key),
                              trailing: Text(_money(entry.value))),
                      ]),
                      _section(
                          'Paiement',
                          [
                            Text(_label(order['payment_method'])),
                            Text(
                                'Paiement : ${_label(order['payment_status'])}'),
                            if (order['payment_method'] == 'cash' &&
                                (num.tryParse('${order['cash_due']}') ?? 0) > 0)
                              Text(
                                  'Cash à encaisser : ${_money(order['cash_due'])}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                          ],
                          color: const Color(0xFFFFF1E3)),
                    ]));
          }));
}

class CourierProfileScreen extends StatefulWidget {
  const CourierProfileScreen({super.key, required this.session});
  final CourierSessionService session;
  @override
  State<CourierProfileScreen> createState() => _CourierProfileState();
}

class _CourierProfileState extends State<CourierProfileScreen> {
  late final _phone = TextEditingController(
      text: widget.session.profile?['phone']?.toString() ?? '');
  bool _busy = false;
  String? _message;
  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) setState(() => _message = success);
    } catch (e) {
      if (mounted) {
        setState(() => _message = CourierSessionService.userMessage(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.session.profile ?? {};
    return ListView(padding: const EdgeInsets.all(20), children: [
      for (final entry in {
        'Prénom': p['first_name'],
        'Nom': p['last_name'],
        'Email': p['email'],
        'Ville': p['city']?['name'],
        'Type': _label(p['courier_type']),
        'Restaurant': p['restaurant']?['name'],
        'Statut': _label(p['status'])
      }.entries)
        ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.key),
            subtitle: Text('${entry.value ?? 'Non renseigné'}')),
      TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Téléphone')),
      if (_message != null) Text(_message!),
      FilledButton(
          onPressed: _busy
              ? null
              : () => _run(() => widget.session.updatePhone(_phone.text),
                  'Téléphone enregistré.'),
          child: const Text('Enregistrer le téléphone')),
      OutlinedButton.icon(
          icon: const Icon(Icons.lock_outline),
          label: const Text('Changer mon mot de passe'),
          onPressed: _busy
              ? null
              : () async {
                  final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => _ProtectedCourierPage(
                              session: widget.session,
                              child: CourierPasswordScreen(
                                  session: widget.session, mandatory: false))));
                  if (mounted && changed == true) {
                    setState(() => _message = 'Mot de passe modifié.');
                  }
                }),
      OutlinedButton(
          onPressed: _busy ? null : () => _run(widget.session.logout, ''),
          child: const Text('Se déconnecter')),
    ]);
  }
}

class CourierNotificationsScreen extends StatelessWidget {
  const CourierNotificationsScreen({super.key, required this.session});
  final CourierSessionService session;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Notifications livreur')),
      bottomNavigationBar: _pageMenu(context, session, 0),
      body: _RemoteData(
          session: session,
          path: 'notifications',
          builder: (context, response, reload) {
            final notifications = response['data'] as List? ?? [];
            return RefreshIndicator(
                onRefresh: reload,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (notifications.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Aucune notification.')),
                      for (final item in notifications)
                        ListTile(
                            title: Text('${item['title']}'),
                            subtitle: Text('${item['body']}'),
                            onTap: () async {
                              try {
                                await session.request(
                                    'notifications/${item['id']}/read',
                                    body: {});
                                NotificationNavigationService.instance
                                    .handlePayload(Map<String, dynamic>.from(
                                        item['data'] as Map? ?? {}));
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              CourierSessionService.userMessage(
                                                  e))));
                                }
                              }
                            }),
                    ]));
          }));
}

class _RemoteData extends StatefulWidget {
  const _RemoteData(
      {super.key,
      required this.session,
      required this.path,
      required this.builder,
      this.query,
      this.refreshInterval});
  final CourierSessionService session;
  final String path;
  final Duration? refreshInterval;
  final Map<String, String>? query;
  final Widget Function(
      BuildContext, Map<String, dynamic>, Future<void> Function()) builder;
  @override
  State<_RemoteData> createState() => _RemoteDataState();
}

class _RemoteDataState extends State<_RemoteData> {
  Map<String, dynamic>? _data;
  String? _error;
  int _version = 0;
  Timer? _timer;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _load();
    if (widget.refreshInterval != null) {
      _timer = Timer.periodic(widget.refreshInterval!, (_) {
        if (!_loading &&
            widget.session.isReady &&
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed) {
          _load();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _loading = true;
    final version = ++_version;
    if (mounted) setState(() => _error = null);
    try {
      final data =
          await widget.session.request(widget.path, query: widget.query);
      if (mounted && version == _version) setState(() => _data = data);
    } catch (e) {
      if (mounted && version == _version) {
        setState(() => _error = CourierSessionService.userMessage(e));
      }
    } finally {
      if (version == _version) _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _ErrorState(_error!, _load);
    if (_data == null) return const Center(child: CircularProgressIndicator());
    return widget.builder(context, _data!, _load);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState(this.message, this.retry);
  final String message;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: retry, child: const Text('Réessayer'))
          ])));
}
