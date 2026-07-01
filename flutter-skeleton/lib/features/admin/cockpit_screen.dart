import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/repositories.dart';

class CockpitData {
  final int totalRefs, nbOk, nbFaible, nbRupture, totalUnites;
  final List<(String, int)> top; // (nom, total sorties du mois)
  final List<int> conso7; // 7 jours
  final DateTime jourBase; // 1er jour du graphe
  final List<Map<String, dynamic>> derniers;
  CockpitData({
    required this.totalRefs,
    required this.nbOk,
    required this.nbFaible,
    required this.nbRupture,
    required this.totalUnites,
    required this.top,
    required this.conso7,
    required this.jourBase,
    required this.derniers,
  });
}

final cockpitProvider = FutureProvider.autoDispose<CockpitData>((ref) async {
  final produits = await ref.read(produitRepoProvider).tous();
  final mvt = ref.read(mouvementRepoProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final debutMois = DateTime(now.year, now.month, 1);
  final il7 = today.subtract(const Duration(days: 6));
  final earliest = il7.isBefore(debutMois) ? il7 : debutMois;

  final derniers = await mvt.derniers(limit: 8);
  final sorties = await mvt.sortiesDepuis(earliest);

  int ok = 0, faible = 0, rupture = 0, unites = 0;
  for (final p in produits) {
    unites += p.stockCourant;
    if (p.stockCourant <= p.seuilRupture) {
      rupture++;
    } else if (p.stockCourant <= p.seuilMini) {
      faible++;
    } else {
      ok++;
    }
  }

  final map = <String, int>{};
  final conso = List<int>.filled(7, 0);
  for (final r in sorties) {
    final d = DateTime.parse(r['cree_le'] as String).toLocal();
    final q = (r['quantite'] ?? 0) as int;
    final nom = (r['produits']?['nom'] ?? '?') as String;
    if (!d.isBefore(debutMois)) map[nom] = (map[nom] ?? 0) + q;
    final jour = DateTime(d.year, d.month, d.day);
    final idx = jour.difference(il7).inDays;
    if (idx >= 0 && idx < 7) conso[idx] += q;
  }
  final top = map.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return CockpitData(
    totalRefs: produits.length,
    nbOk: ok,
    nbFaible: faible,
    nbRupture: rupture,
    totalUnites: unites,
    top: top.take(5).map((e) => (e.key, e.value)).toList(),
    conso7: conso,
    jourBase: il7,
    derniers: derniers,
  );
});

class CockpitScreen extends ConsumerWidget {
  const CockpitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cockpitProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cockpit')),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (d) => RefreshIndicator(
              onRefresh: () => ref.refresh(cockpitProvider.future),
              child: ListView(
                padding: const EdgeInsets.all(Dim.pad),
                children: [
                  _statsRow(d),
                  const SizedBox(height: 16),
                  _bloc('Consommation (7 jours)', _graphe(d)),
                  const SizedBox(height: 16),
                  _bloc('Produits les plus utilisés (ce mois)', _top(d)),
                  const SizedBox(height: 16),
                  _bloc('Derniers mouvements', _derniers(d)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Indicateurs ──
  Widget _statsRow(CockpitData d) {
    return Column(
      children: [
        Row(children: [
          _stat('${d.totalRefs}', 'Références', AppColors.primary,
              const Color(0xFFE7EEFB)),
          const SizedBox(width: 10),
          _stat('${d.totalUnites}', 'Unités', AppColors.primaryDark,
              const Color(0xFFE7EEFB)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _stat('${d.nbRupture}', 'Ruptures', AppColors.rupture,
              AppColors.ruptureBg),
          const SizedBox(width: 10),
          _stat('${d.nbFaible}', 'Faibles', AppColors.faible,
              AppColors.faibleBg),
          const SizedBox(width: 10),
          _stat('${d.nbOk}', 'OK', AppColors.ok, AppColors.okBg),
        ]),
      ],
    );
  }

  Widget _stat(String n, String label, Color c, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Dim.radius),
        ),
        child: Column(children: [
          Text(n,
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w700, color: c)),
          Text(label,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: c)),
        ]),
      ),
    );
  }

  // ── Conteneur de bloc ──
  Widget _bloc(String titre, Widget contenu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Dim.radius),
        boxShadow: Shadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          contenu,
        ],
      ),
    );
  }

  // ── Mini graphe barres ──
  Widget _graphe(CockpitData d) {
    final maxV = d.conso7.fold<int>(1, (m, v) => v > m ? v : m);
    const jours = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final v = d.conso7[i];
          final j = d.jourBase.add(Duration(days: i));
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$v',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    height: (90 * v / maxV).clamp(4, 90).toDouble(),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: AppColors.gradSortie,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(jours[(j.weekday - 1) % 7],
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSoft)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Top produits (barres proportionnelles) ──
  Widget _top(CockpitData d) {
    if (d.top.isEmpty) {
      return const Text('Aucune sortie ce mois-ci',
          style: TextStyle(color: AppColors.textSoft, fontSize: 15));
    }
    final maxV = d.top.first.$2;
    return Column(
      children: d.top.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(e.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600))),
                  Text('${e.$2}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: maxV == 0 ? 0 : e.$2 / maxV,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEBEFF6),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Derniers mouvements ──
  Widget _derniers(CockpitData d) {
    if (d.derniers.isEmpty) {
      return const Text('Aucun mouvement',
          style: TextStyle(color: AppColors.textSoft, fontSize: 15));
    }
    String fmt(String iso) {
      final dt = DateTime.parse(iso).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
    }

    return Column(
      children: d.derniers.map((r) {
        final type = (r['type'] ?? '') as String;
        final entree = type == 'Entrée';
        final nom = (r['produits']?['nom'] ?? '?') as String;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: entree ? AppColors.okBg : const Color(0xFFE7EEFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                    entree
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: entree ? AppColors.ok : AppColors.primary,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('$type · ${fmt(r['cree_le'] as String)}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSoft)),
                  ],
                ),
              ),
              Text('${entree ? "+" : "−"}${r['quantite']}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: entree ? AppColors.ok : AppColors.primary)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
