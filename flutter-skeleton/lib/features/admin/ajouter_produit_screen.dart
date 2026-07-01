import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';

/// Écran ADMIN — ajout de produit. Ici le clavier est autorisé
/// (c'est l'admin, pas l'opérateur : la règle "sans clavier" vise les opérateurs).
class AjouterProduitScreen extends ConsumerStatefulWidget {
  const AjouterProduitScreen({super.key});
  @override
  ConsumerState<AjouterProduitScreen> createState() => _State();
}

class _State extends ConsumerState<AjouterProduitScreen> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _unite = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _seuilMini = TextEditingController(text: '0');
  final _seuilCible = TextEditingController(text: '0');

  String? _categorieId;
  String? _siteId;
  String? _photoUrl;
  bool _photoEnCours = false;
  bool _enCours = false;

  /// Génère une référence lisible à partir du nom.
  /// "Détergent sol 5L" -> "DETERGENT-SOL-5L"
  static String genererRef(String nom) {
    var s = nom.trim().toUpperCase();
    const from = 'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ';
    const to = 'AAAAAACEEEEIIIINOOOOOUUUUY';
    for (var i = 0; i < from.length; i++) {
      s = s.replaceAll(from[i], to[i]);
    }
    s = s.replaceAll(RegExp(r'[^A-Z0-9]+'), '-');
    s = s.replaceAll(RegExp(r'^-+|-+$'), '');
    return s;
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

  @override
  void dispose() {
    for (final c in [_nom, _unite, _stock, _seuilMini, _seuilCible]) {
      c.dispose();
    }
    super.dispose();
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
      final repo = ref.read(produitRepoProvider);
      await repo.ajouterAdmin(
        pin: pin,
        ref: genererRef(_nom.text),
        nom: _nom.text.trim(),
        categorieId: _categorieId,
        siteId: _siteId,
        unite: _unite.text.trim().isEmpty ? null : _unite.text.trim(),
        stockInitial: int.tryParse(_stock.text) ?? 0,
        seuilMini: int.tryParse(_seuilMini.text) ?? 0,
        seuilCible: int.tryParse(_seuilCible.text) ?? 0,
        photoUrl: _photoUrl,
      );
      if (!mounted) return;
      buzzSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ « ${_nom.text} » ajouté')),
      );
      context.pop();
    } catch (e) {
      // Message serveur (ex. "Accès refusé : compte admin requis" ou doublon)
      _erreur(e.toString().replaceFirst('PostgrestException(', '').split(',').first);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  void _erreur(String msg) {
    buzz(200);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('⚠ $msg'), backgroundColor: AppColors.rupture));
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(_categoriesProvider);
    final sites = ref.watch(_sitesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('➕ Ajouter un produit')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(Dim.pad),
          children: [
            _sectionPhoto(),
            const SizedBox(height: 14),
            _champ(_nom, 'Nom du produit *',
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null),
            if (_nom.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14, left: 4),
                child: Row(children: [
                  const Icon(Icons.qr_code_2_rounded,
                      size: 18, color: AppColors.textSoft),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Référence auto : ${genererRef(_nom.text)}',
                        style: const TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
            cats.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Catégories: $e'),
              data: (list) => _dropdown<Categorie>(
                'Catégorie', list, _categorieId,
                (c) => c.id, (c) => c.nom, (v) => setState(() => _categorieId = v)),
            ),
            sites.when(
              loading: () => const SizedBox(),
              error: (e, _) => const SizedBox(),
              data: (list) => _dropdown<Site>(
                'Site', list, _siteId,
                (s) => s.id, (s) => s.nom, (v) => setState(() => _siteId = v)),
            ),
            _champ(_unite, 'Unité', hint: 'bidon, sac, boîte…'),
            _champ(_stock, 'Stock initial', number: true),
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
    );
  }

  Widget _sectionPhoto() {
    return GestureDetector(
      onTap: _photoEnCours ? null : _prendrePhoto,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(Dim.radius),
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
                          avatar: Icon(Icons.refresh, size: 18),
                          label: Text('Changer'),
                        ),
                      ),
                    ),
                  ])
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Prendre une photo (recommandé)',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
      ),
    );
  }

  Widget _champ(TextEditingController c, String label,
      {String? hint,
      bool number = false,
      String? Function(String?)? validator,
      ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        inputFormatters:
            number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))] : null,
        style: const TextStyle(fontSize: 20, color: AppColors.textMain),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  Widget _dropdown<T>(String label, List<T> items, String? value,
      String Function(T) id, String Function(T) nom, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
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
