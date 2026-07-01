import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';

class MouvementArgs {
  final Produit produit;
  final String mode; // 'Entrée' | 'Sortie'
  MouvementArgs({required this.produit, required this.mode});
}

class MouvementScreen extends ConsumerStatefulWidget {
  const MouvementScreen({super.key, required this.args});
  final MouvementArgs args;

  @override
  ConsumerState<MouvementScreen> createState() => _MouvementScreenState();
}

class _MouvementScreenState extends ConsumerState<MouvementScreen> {
  int _qte = 1;
  bool _enCours = false;
  bool _confirme = false;
  int _stockApres = 0;
  String? _photoUrl;
  bool _photoEnCours = false;

  bool get _estSortie => widget.args.mode == 'Sortie';

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.args.produit.photoUrl;
  }

  Future<void> _prendrePhoto() async {
    setState(() => _photoEnCours = true);
    try {
      final url = await ref
          .read(produitRepoProvider)
          .capturerEtDefinirPhoto(widget.args.produit.id);
      if (!mounted) return;
      if (url != null) {
        buzzSuccess();
        setState(() => _photoUrl = url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('⚠ Photo : $e')));
      }
    } finally {
      if (mounted) setState(() => _photoEnCours = false);
    }
  }

  Future<void> _valider() async {
    setState(() => _enCours = true);
    final p = widget.args.produit;
    final op = ref.read(operateurCourantProvider);
    final lieu = ref.read(sessionLieuProvider);
    try {
      await ref.read(mouvementRepoProvider).enregistrer(
            type: widget.args.mode,
            produitId: p.id,
            siteId: lieu?.id,
            quantite: _qte,
            operateurId: op?.id,
          );
      final maj = lieu != null
          ? await ref.read(produitRepoProvider).parIdLieu(p.id, lieu.id)
          : await ref.read(produitRepoProvider).parId(p.id);
      ref.invalidate(stocksLieuProvider);
      if (!mounted) return;
      buzzSuccess();
      setState(() {
        _confirme = true;
        _stockApres = maj.stockCourant;
        _enCours = false;
      });
    } catch (e) {
      // Réseau coupé / erreur serveur : message rassurant, pas de plantage.
      if (!mounted) return;
      buzz(200);
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.rupture,
          content: const Text(
              "Pas enregistré : vérifiez la connexion et réessayez.",
              style: TextStyle(fontSize: 16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.args.produit;
    if (_confirme) return _ecranConfirmation(p);

    final restant =
        _estSortie ? p.stockCourant - _qte : p.stockCourant + _qte;
    final ruptureSortie = _estSortie && p.stockCourant <= 0;

    return Scaffold(
      appBar: AppBar(title: Text(_estSortie ? 'Sortie' : 'Entrée')),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Dim.pad),
            child: Column(
              children: [
                // Carte produit
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Dim.radius),
                    boxShadow: Shadows.soft,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _photo(p),
                      const SizedBox(height: 14),
                      Text(p.nom,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      StatusPill(
                          stock: p.stockCourant,
                          seuilMini: p.seuilMini,
                          seuilRupture: p.seuilRupture,
                          large: true),
                    ],
                  ),
                ),
                const Spacer(),
                if (ruptureSortie) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.ruptureBg,
                      borderRadius: BorderRadius.circular(Dim.radius),
                    ),
                    child: const Column(children: [
                      Icon(Icons.error_rounded,
                          color: AppColors.rupture, size: 48),
                      SizedBox(height: 10),
                      Text('Stock épuisé',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.rupture)),
                      SizedBox(height: 4),
                      Text('Impossible de sortir ce produit.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: AppColors.rupture)),
                    ]),
                  ),
                  const Spacer(),
                  BigButton(
                    label: 'RETOUR ACCUEIL',
                    icon: Icons.home_rounded,
                    gradient: AppColors.gradResponsable,
                    onTap: () => context.go('/home'),
                  ),
                ] else ...[
                  Text(_estSortie ? 'Combien en sortir ?' : 'Combien en entrer ?',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSoft)),
                  const SizedBox(height: 12),
                  QuantityStepper(
                      value: _qte,
                      max: _estSortie ? p.stockCourant : 999,
                      onChanged: (v) => setState(() => _qte = v)),
                  const SizedBox(height: 18),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: Shadows.soft,
                    ),
                    child: Text('Il restera : $restant',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  _enCours
                      ? const CircularProgressIndicator()
                      : BigButton(
                          label:
                              _estSortie ? 'VALIDER LA SORTIE' : "VALIDER L'ENTRÉE",
                          icon: Icons.check_rounded,
                          gradient: _estSortie
                              ? AppColors.gradSortie
                              : AppColors.gradEntree,
                          onTap: _valider,
                        ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Annuler',
                        style:
                            TextStyle(fontSize: 18, color: AppColors.textSoft)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photo(Produit p) {
    if (_photoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Dim.radius),
        child: CachedNetworkImage(
          imageUrl: _photoUrl!,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    // Pas de photo : proposer à l'opérateur d'en prendre une (photothèque).
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(Dim.radius),
      ),
      child: _photoEnCours
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2, size: 56, color: Colors.grey),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _prendrePhoto,
                  icon: const Icon(Icons.photo_camera, size: 26),
                  label: const Text('Prendre une photo',
                      style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
    );
  }

  Widget _ecranConfirmation(Produit p) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
          padding: const EdgeInsets.all(Dim.pad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.gradEntree),
                  shape: BoxShape.circle,
                  boxShadow: Shadows.colored(AppColors.ok),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 76),
              ),
              const SizedBox(height: 24),
              const Text("C'est enregistré !",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(Dim.radius),
                  boxShadow: Shadows.soft,
                ),
                child: Column(
                  children: [
                    Text('${p.nom}   ${_estSortie ? "−" : "+"}$_qte',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Nouveau stock : $_stockApres',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
              ),
              const Spacer(),
              BigButton(
                label: 'AUTRE PRODUIT',
                icon: Icons.add_rounded,
                gradient: AppColors.gradSortie,
                onTap: () => context.pushReplacement('/scan?mode=${widget.args.mode}'),
              ),
              const SizedBox(height: 12),
              BigButton(
                label: 'RETOUR ACCUEIL',
                icon: Icons.home_rounded,
                gradient: AppColors.gradResponsable,
                onTap: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
