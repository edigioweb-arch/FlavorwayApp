import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../services/api_client.dart';
import '../../services/restaurant_workspace_service.dart';

class EditMenuScreen extends StatefulWidget {
  const EditMenuScreen({super.key, this.workspace});
  final RestaurantWorkspaceService? workspace;
  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  RestaurantWorkspaceService get api =>
      widget.workspace ?? RestaurantWorkspaceService.instance;
  Map<String, dynamic>? catalog;
  bool loading = true;
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
      final data = await api.fetchCatalog();
      if (mounted) setState(() => catalog = data);
    } catch (_) {
      if (mounted)
        setState(() => error = 'Impossible de charger votre catalogue.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([Map? product]) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RestaurantProductEditor(
                workspace: api, catalog: catalog!, product: product)));
    if (mounted) await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF8F4FA),
        appBar: AppBar(
            title: Text('Gestion des menus',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700))),
        floatingActionButton: catalog == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => edit(),
                label: const Text('Ajouter un plat'),
                icon: const Icon(Icons.add)),
        body: RefreshIndicator(
            onRefresh: load,
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  if (loading)
                    const Center(child: CircularProgressIndicator())
                  else if (error != null) ...[
                    Text(error!),
                    TextButton(onPressed: load, child: const Text('Réessayer'))
                  ] else ...[
                    Text(
                        (catalog?['restaurant']?['name'] ?? 'Votre restaurant')
                            .toString(),
                        style: GoogleFonts.poppins(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                        'Menus : ${(catalog?['menus'] as List? ?? []).map((m) => m['name']).join(' • ')}'),
                    Text(
                        'Catégories : ${(catalog?['categories'] as List? ?? []).map((m) => m['name']).join(' • ')}'),
                    if ((catalog?['products'] as List? ?? []).isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                              'Aucun produit. Ajoutez votre premier plat.')),
                    for (final product in catalog?['products'] as List? ?? [])
                      Card(
                          child: ListTile(
                        title: Text(product['name'].toString()),
                        subtitle: Text(
                            '${product['sale_price'] ?? product['base_price']} ${product['currency_code']} • ${product['is_available'] == true ? 'Disponible' : 'Indisponible'}'),
                        trailing: const Icon(Icons.edit),
                        onTap: () => edit(product as Map),
                      )),
                  ],
                ])),
      );
}

class RestaurantProductEditor extends StatefulWidget {
  const RestaurantProductEditor(
      {super.key,
      required this.workspace,
      required this.catalog,
      this.product});
  final RestaurantWorkspaceService workspace;
  final Map<String, dynamic> catalog;
  final Map? product;
  @override
  State<RestaurantProductEditor> createState() =>
      _RestaurantProductEditorState();
}

class _RestaurantProductEditorState extends State<RestaurantProductEditor> {
  final form = GlobalKey<FormState>();
  late Map<String, dynamic> data;
  bool saving = false;
  String? error;
  XFile? image;
  @override
  void initState() {
    super.initState();
    data = widget.product == null
        ? {
            'name': '',
            'description': '',
            'base_price': '',
            'sale_price': null,
            'is_available': true,
            'menu_id': null,
            'category_id': null,
            'menu_name': 'Carte',
            'category_name': '',
            'options': <dynamic>[]
          }
        : Map<String, dynamic>.from(jsonDecode(jsonEncode(widget.product)));
  }

  Widget field(Map target, String key, String label,
          {bool required = false, bool number = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          initialValue: target[key]?.toString() ?? '',
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          onChanged: (value) => target[key] = value,
          validator: (value) {
            if (required && (value ?? '').trim().isEmpty)
              return 'Champ obligatoire';
            if (number &&
                (value ?? '').isNotEmpty &&
                (double.tryParse(value!.replaceAll(',', '.')) == null ||
                    double.parse(value.replaceAll(',', '.')) < 0))
              return 'Montant invalide';
            return null;
          },
        ),
      );
  Widget association(String type, String label, String listKey) =>
      Column(children: [
        DropdownButtonFormField<int>(
            value: data['${type}_id'] as int?,
            decoration: InputDecoration(labelText: label),
            items: [
              const DropdownMenuItem<int>(
                  value: null, child: Text('Créer / saisir un nom')),
              for (final entry in widget.catalog[listKey] as List)
                DropdownMenuItem(
                    value: entry['id'] as int, child: Text(entry['name']))
            ],
            onChanged: (id) => setState(() => data['${type}_id'] = id)),
        if (data['${type}_id'] == null)
          field(data, '${type}_name', 'Nom $label', required: true),
      ]);
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final payload = <String, dynamic>{
        for (final key in [
          'name',
          'description',
          'is_available',
          'menu_id',
          'category_id',
          'menu_name',
          'category_name',
          'options'
        ])
          key: data[key]
      };
      payload['base_price'] =
          double.parse(data['base_price'].toString().replaceAll(',', '.'));
      payload['sale_price'] = double.tryParse(
          (data['sale_price'] ?? '').toString().replaceAll(',', '.'));
      for (final option in payload['options'] as List) {
        for (final value in option['values'] as List) {
          value['price_delta'] = double.parse(
              value['price_delta'].toString().replaceAll(',', '.'));
        }
      }
      await widget.workspace.saveProduct(payload,
          id: widget.product?['id'] as int?,
          image: image == null
              ? null
              : await http.MultipartFile.fromPath('image', image!.path));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(() => error = e is ApiException
            ? e.message
            : 'Produit non enregistré. Réessayez.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !saving,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F4FA),
        appBar: AppBar(
            title: Text(widget.product == null
                ? 'Ajouter un plat'
                : 'Modifier le plat')),
        body: AbsorbPointer(
            absorbing: saving,
            child: Form(
                key: form,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  field(data, 'name', 'Nom', required: true),
                  field(data, 'description', 'Description'),
                  field(data, 'base_price', 'Prix (XAF)',
                      required: true, number: true),
                  field(data, 'sale_price', 'Prix promotionnel (facultatif)',
                      number: true),
                  association('menu', 'Menu', 'menus'),
                  association('category', 'Catégorie', 'categories'),
                  SwitchListTile(
                      title: const Text('Disponible'),
                      value: data['is_available'] == true,
                      onChanged: (v) =>
                          setState(() => data['is_available'] = v)),
                  OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: Text(image?.name ?? 'Choisir une image'),
                      onPressed: () async {
                        final file = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (mounted) setState(() => image = file);
                      }),
                  for (final option in data['options'] as List)
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(children: [
                              field(option, 'name', 'Groupe d’options',
                                  required: true),
                              DropdownButtonFormField<String>(
                                  value: option['selection_type'],
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'single',
                                        child: Text('Un seul choix')),
                                    DropdownMenuItem(
                                        value: 'multiple',
                                        child: Text('Plusieurs choix'))
                                  ],
                                  onChanged: (v) => setState(
                                      () => option['selection_type'] = v)),
                              SwitchListTile(
                                  title: const Text('Obligatoire'),
                                  value: option['is_required'] == true,
                                  onChanged: (v) => setState(
                                      () => option['is_required'] = v)),
                              SwitchListTile(
                                  title: const Text('Groupe actif'),
                                  value: option['is_active'] == true,
                                  onChanged: (v) =>
                                      setState(() => option['is_active'] = v)),
                              for (final value in option['values'] as List)
                                Column(children: [
                                  field(value, 'name', 'Supplément',
                                      required: true),
                                  field(value, 'price_delta',
                                      'Supplément de prix',
                                      required: true, number: true),
                                  SwitchListTile(
                                      title: const Text('Option disponible'),
                                      value: value['is_available'] == true,
                                      onChanged: (v) => setState(
                                          () => value['is_available'] = v)),
                                ]),
                              TextButton(
                                  onPressed: () => setState(() =>
                                      (option['values'] as List).add({
                                        'name': '',
                                        'price_delta': 0,
                                        'is_available': true
                                      })),
                                  child: const Text('Ajouter une valeur')),
                            ]))),
                  TextButton(
                      onPressed: () =>
                          setState(() => (data['options'] as List).add({
                                'name': '',
                                'selection_type': 'single',
                                'is_required': false,
                                'is_active': true,
                                'values': [
                                  {
                                    'name': '',
                                    'price_delta': 0,
                                    'is_available': true
                                  }
                                ]
                              })),
                      child: const Text('Ajouter un groupe d’options')),
                  ElevatedButton(
                      onPressed: saving ? null : save,
                      child: Text(saving ? 'Enregistrement…' : 'Enregistrer')),
                ]))),
      ));
}
