import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';

enum FiltreStock { tous, ok, faible, rupture }

class StocksScreen extends ConsumerStatefulWidget {
  const StocksScreen({super.key});
  @override
  ConsumerState<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends ConsumerState<StocksScreen> {
  FiltreStock _filtre = FiltreStock.tous;
  String _query = '';

  FiltreStock _statut(Produit p) {
    if (p.stockCourant <= p.seuilRupture) return FiltreStock.rupture;
    if (p.stockCourant <= p.seuilMini) return FiltreStock.faible;
    return FiltreStock.ok;
  }

  void _toggle(FiltreStock f) =>
      setState(() => _filtre = (_filtre == f) ? FiltreStock.tous : f);

  @override
  Widget build(BuildContext context) {
    final lieu = ref.watch(sessionLieuProvider);
    final lieux = ref.watch(lieuxProvider).valueOrNull ?? const <Site>[];
    final async = ref.watch(stocksLieuProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stocks')),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (lieux.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Dim.pad, 8, Dim.pad, 4),
                  child: _selecteurLieu(lieux, lieu),
                ),
              if (lieu == null)
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(Dim.pad),
                      child: Text(
                        'Choisissez d\'abord un lieu\n(en haut ou sur l\'accueil)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: AppColors.textSoft),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: async.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur : $e')),
                    data: (tous) => _contenu(tous),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenu(List<Produit> tous) {
    final ok = tous.where((p) => _statut(p) == FiltreStock.ok).length;
    final faible = tous.where((p) => _statut(p) == FiltreStock.faible).length;
    final rupture = tous.where((p) => _statut(p) == FiltreStock.rupture).length;

    var produits = _filtre == FiltreStock.tous
        ? tous
        : tous.where((p) => _statut(p) == _filtre).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      produits = produits.where((p) => p.nom.toLowerCase().contains(q)).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Dim.pad, 4, Dim.pad, 0),
          child: Row(children: [
            _stat('$ok', 'OK', AppColors.ok, AppColors.okBg, FiltreStock.ok),
            const SizedBox(width: 10),
            _stat('$faible', 'Faibles', AppColors.faible, AppColors.faibleBg,
                FiltreStock.faible),
            const SizedBox(width: 10),
            _stat('$rupture', 'Ruptures', AppColors.rupture, AppColors.ruptureBg,
                FiltreStock.rupture),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Dim.pad, 12, Dim.pad, 8),
          child: _recherche(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(stocksLieuProvider.future),
            child: produits.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 60),
                    Center(
                        child: Text('Aucun produit à ce lieu',
                            style: TextStyle(
                                fontSize: 18, color: AppColors.textSoft))),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        Dim.pad, 4, Dim.pad, Dim.pad),
                    itemCount: produits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _carte(produits[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _selecteurLieu(List<Site> lieux, Site? courant) {
    final sites = lieux.where((l) => l.type == 'Site').toList();
    final presta = lieux.where((l) => l.type == 'Prestation').toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Dim.radius),
        boxShadow: Shadows.soft,
      ),
      child: Row(children: [
        const Icon(Icons.place_rounded, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: courant?.id,
              hint: const Text('Choisir un lieu'),
              items: [
                ...sites.map((s) => DropdownMenuItem<String?>(
                    value: s.id, child: Text('📍 ${s.nom}'))),
                ...presta.map((s) => DropdownMenuItem<String?>(
                    value: s.id, child: Text('🧾 ${s.nom}  ·  prestation'))),
              ],
              onChanged: (v) {
                final l = lieux.where((x) => x.id == v).toList();
                ref.read(sessionLieuProvider.notifier).state =
                    l.isEmpty ? null : l.first;
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _stat(String n, String label, Color c, Color bg, FiltreStock f) {
    final sel = _filtre == f;
    return Expanded(
      child: GestureDetector(
        onTap: () => _toggle(f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? c : bg,
            borderRadius: BorderRadius.circular(Dim.radius),
            boxShadow: sel ? Shadows.colored(c) : null,
          ),
          child: Column(children: [
            Text(n,
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : c)),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : c)),
          ]),
        ),
      ),
    );
  }

  Widget _recherche() {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        hintText: 'Rechercher un produit…',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSoft),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dim.radius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _carte(Produit p) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Dim.radius),
        boxShadow: Shadows.soft,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 60,
              height: 60,
              child: p.photoUrl != null
                  ? CachedNetworkImage(imageUrl: p.photoUrl!, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFEEF1F7),
                      child: const Icon(Icons.inventory_2_rounded,
                          size: 32, color: AppColors.textSoft)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(p.nom,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          StatusPill(
              stock: p.stockCourant,
              seuilMini: p.seuilMini,
              seuilRupture: p.seuilRupture),
        ],
      ),
    );
  }
}
