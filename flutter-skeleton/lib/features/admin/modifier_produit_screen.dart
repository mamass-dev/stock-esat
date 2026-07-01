import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';

class ModifierProduitScreen extends ConsumerStatefulWidget {
  const ModifierProduitScreen({super.key, required this.produit});
  final Produit produit;
  @override
  ConsumerState<ModifierProduitScreen> createState() => _State();
}

class _State extends ConsumerState<ModifierProduitScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _unite;
  late final TextEditingController _seuilMini;
  late final TextEditingController _seuilCible;

  String? _categorieId;
  String? _siteId;
  String? _photoUrl;
  bool _photoEnCours = false;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    final p = widget.produit;
    _nom = TextEditingController(text: p.nom);
    _unite = TextEditingController(text: p.unite ?? '');
    _seuilMini = TextEditingController(text: '${p.seuilMini}');
    _seuilCible = TextEditingController(text: '${p.seuilCible}');
    _categorieId = p.categorieId;
    _siteId = p.siteId;
    _photoUrl = p.photoUrl;
  }

  @override
  void dispose() {
    for (final c in [_nom, _unite, _seuilMini, _seuilCible]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _prendrePhoto() async {
    setState(() => _photoEnCours = true);
    try {
      final url = await ref.read(produitRepoProvider).capturerPhotoNouvelle();
      if (url != null && mounted) {
        buzz();
        setState(() => _photoUrl = url);
      }
    } catch (e) {
      _erreur('Photo : $e');
    } finally {
      if (mounted) setState(() => _photoEnCours = false);
    }
  }

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate()) return;
    final pin = ref.read(sessionPinProvider);
    if (pin == null) {
      _erreur('Session expirée, reconnectez-vous.');
      return;
    }
    setState(() => _enCours = true);
    try {
      final maj = await ref.read(produitRepoProvider).modifierAdmin(
            pin: pin,
            produitId: widget.produit.id,
            nom: _nom.text.trim(),
            categorieId: _categorieId,
            siteId: _siteId,
            unite: _unite.text.trim().isEmpty ? null : _unite.text.trim(),
            seuilMini: int.tryParse(_seuilMini.text) ?? 0,
            seuilCible: int.tryParse(_seuilCible.text) ?? 0,
            photoUrl: _photoUrl,
          );
      if (!mounted) return;
      buzzSuccess();
      context.pop(maj);
    } catch (e) {
      _erreur(e.toString().replaceFirst('PostgrestException(', '').split(',').first);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  void _erreur(String msg) {
    buzz(200);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚠ $msg'), backgroundColor: AppColors.rupture));
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(_categoriesProvider);
    final sites = ref.watch(_sitesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le produit')),
      body: AppBackground(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(Dim.pad),
            children: [
              _sectionPhoto(),
              const SizedBox(height: 14),
              _champ(_nom, 'Nom du produit *',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Obligatoire' : null),
              cats.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Catégories : $e'),
                data: (list) => _dropdown<Categorie>('Catégorie', list,
                    _categorieId, (c) => c.id, (c) => c.nom,
                    (v) => setState(() => _categorieId = v)),
              ),
              sites.when(
                loading: () => const SizedBox(),
                error: (e, _) => const SizedBox(),
                data: (list) => _dropdown<Site>('Site', list, _siteId,
                    (s) => s.id, (s) => s.nom, (v) => setState(() => _siteId = v)),
              ),
              _champ(_unite, 'Unité', hint: 'bidon, sac, boîte…'),
              _champ(_seuilMini, 'Seuil mini (alerte 🟠)', number: true),
              _champ(_seuilCible, 'Seuil cible (à recommander)', number: true),
              const SizedBox(height: 24),
              _enCours
                  ? const Center(child: CircularProgressIndicator())
                  : BigButton(
                      label: 'ENREGISTRER',
                      icon: Icons.save_rounded,
                      gradient: AppColors.gradEntree,
                      onTap: _enregistrer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionPhoto() {
    return GestureDetector(
      onTap: _photoEnCours ? null : _prendrePhoto,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Dim.radius),
          boxShadow: Shadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: _photoEnCours
            ? const Center(child: CircularProgressIndicator())
            : _photoUrl != null
                ? Stack(fit: StackFit.expand, children: [
                    CachedNetworkImage(imageUrl: _photoUrl!, fit: BoxFit.cover),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Chip(
                            avatar: Icon(Icons.photo_camera, size: 18),
                            label: Text('Changer')),
                      ),
                    ),
                  ])
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Ajouter une photo',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
      ),
    );
  }

  Widget _champ(TextEditingController c, String label,
      {String? hint, bool number = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        inputFormatters:
            number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))] : null,
        style: const TextStyle(fontSize: 20, color: AppColors.textMain),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
        ),
        validator: validator,
      ),
    );
  }

  Widget _dropdown<T>(String label, List<T> items, String? value,
      String Function(T) id, String Function(T) nom,
      ValueChanged<String?> onChanged) {
    // valeur inconnue -> null pour éviter l'assertion
    final ids = items.map(id).toSet();
    final v = (value != null && ids.contains(value)) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: v,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: id(e), child: Text(nom(e))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

final _categoriesProvider =
    FutureProvider((ref) => ref.read(produitRepoProvider).categories());
final _sitesProvider =
    FutureProvider((ref) => ref.read(produitRepoProvider).sites());
