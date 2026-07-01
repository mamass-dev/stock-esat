import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';

final produitsProvider = FutureProvider<List<Produit>>(
    (ref) => ref.read(produitRepoProvider).tous());

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

  void _toggle(FiltreStock f) => setState(
      () => _filtre = (_filtre == f) ? FiltreStock.tous : f);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(produitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Stocks')),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (tous) {
              final ok = tous.where((p) => _statut(p) == FiltreStock.ok).length;
              final faible =
                  tous.where((p) => _statut(p) == FiltreStock.faible).length;
              final rupture =
                  tous.where((p) => _statut(p) == FiltreStock.rupture).length;

              var produits = _filtre == FiltreStock.tous
                  ? tous
                  : tous.where((p) => _statut(p) == _filtre).toList();
              if (_query.isNotEmpty) {
                final q = _query.toLowerCase();
                produits =
                    produits.where((p) => p.nom.toLowerCase().contains(q)).toList();
              }

              return Column(
                children: [
                  // ── Aperçu chiffré (cliquable = filtre) ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Dim.pad, 6, Dim.pad, 0),
                    child: Row(
                      children: [
                        _stat('$ok', 'OK', AppColors.ok, AppColors.okBg,
                            FiltreStock.ok),
                        const SizedBox(width: 10),
                        _stat('$faible', 'Faibles', AppColors.faible,
                            AppColors.faibleBg, FiltreStock.faible),
                        const SizedBox(width: 10),
                        _stat('$rupture', 'Ruptures', AppColors.rupture,
                            AppColors.ruptureBg, FiltreStock.rupture),
                      ],
                    ),
                  ),
                  // ── Recherche ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Dim.pad, 14, Dim.pad, 10),
                    child: _recherche(),
                  ),
                  // ── Ligne d'info / réinitialiser ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dim.pad),
                    child: Row(
                      children: [
                        Text('${produits.length} produit${produits.length > 1 ? "s" : ""}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSoft)),
                        const Spacer(),
                        if (_filtre != FiltreStock.tous)
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _filtre = FiltreStock.tous),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Tout voir'),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref.refresh(produitsProvider.future),
                      child: produits.isEmpty
                          ? ListView(children: const [
                              SizedBox(height: 60),
                              Center(
                                  child: Text('Aucun produit',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: AppColors.textSoft))),
                            ])
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  Dim.pad, 4, Dim.pad, Dim.pad),
                              itemCount: produits.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) => _carte(produits[i]),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
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
          child: Column(
            children: [
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
            ],
          ),
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
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => setState(() => _query = ''),
              )
            : null,
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
    final st = _statut(p);
    final (c, bg, mot) = switch (st) {
      FiltreStock.rupture => (AppColors.rupture, AppColors.ruptureBg, 'Rupture'),
      FiltreStock.faible => (AppColors.faible, AppColors.faibleBg, 'Faible'),
      _ => (AppColors.ok, AppColors.okBg, 'OK'),
    };
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
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 66,
              height: 66,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600, height: 1.15)),
                const SizedBox(height: 4),
                Text(mot,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: c)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Stock mis en avant
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('${p.stockCourant}',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w700, color: c)),
                if (p.unite != null)
                  Text(p.unite!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
