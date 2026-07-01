import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _banniereLieu(BuildContext context, WidgetRef ref) {
    final lieu = ref.watch(sessionLieuProvider);
    final vide = lieu == null;
    return GestureDetector(
      onTap: () => _choisirLieu(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: vide
                  ? const [Color(0xFFF0A93B), Color(0xFFE8890C)]
                  : AppColors.gradSortie),
          borderRadius: BorderRadius.circular(Dim.radius),
          boxShadow: Shadows.colored(
              vide ? AppColors.faible : AppColors.primary),
        ),
        child: Row(children: [
          const Icon(Icons.place_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lieu de travail',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text(vide ? 'Choisir un lieu' : lieu.nom,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.unfold_more_rounded, color: Colors.white, size: 26),
        ]),
      ),
    );
  }

  Future<void> _choisirLieu(BuildContext context, WidgetRef ref) async {
    final lieux = await ref.read(lieuxProvider.future);
    if (!context.mounted) return;
    final sites = lieux.where((l) => l.type == 'Site').toList();
    final presta = lieux.where((l) => l.type == 'Prestation').toList();

    Widget tuile(Site l, String emoji) => ListTile(
          leading: Text(emoji, style: const TextStyle(fontSize: 22)),
          title: Text(l.nom,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          onTap: () {
            ref.read(sessionLieuProvider.notifier).state = l;
            Navigator.pop(context);
          },
        );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text('Choisir un lieu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            if (sites.isNotEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 2),
                child: Text('Sites',
                    style: TextStyle(
                        color: AppColors.textSoft,
                        fontWeight: FontWeight.w600)),
              ),
            ...sites.map((l) => tuile(l, '📍')),
            if (presta.isNotEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 2),
                child: Text('Prestations',
                    style: TextStyle(
                        color: AppColors.textSoft,
                        fontWeight: FontWeight.w600)),
              ),
            ...presta.map((l) => tuile(l, '🧾')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final op = ref.watch(operateurCourantProvider);
    final initiale = (op?.nom.isNotEmpty ?? false) ? op!.nom[0].toUpperCase() : '?';

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Dim.pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : avatar + salutation + déconnexion
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.gradSortie),
                        shape: BoxShape.circle,
                        boxShadow: Shadows.colored(AppColors.primary),
                      ),
                      alignment: Alignment.center,
                      child: Text(initiale,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bonjour 👋',
                              style: TextStyle(
                                  fontSize: 16, color: AppColors.textSoft)),
                          Text(op?.nom ?? '',
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.logout_rounded,
                          size: 26, color: AppColors.textSoft),
                      onPressed: () {
                        ref.read(operateurCourantProvider.notifier).state = null;
                        ref.read(sessionPinProvider.notifier).state = null;
                        context.go('/login');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _banniereLieu(context, ref),
                const SizedBox(height: 16),
                Text('Que voulez-vous faire ?',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSoft)),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: Dim.gap,
                    crossAxisSpacing: Dim.gap,
                    childAspectRatio: 0.92,
                    children: [
                      BigTile(
                        label: 'ENTRÉE',
                        icon: Icons.login_rounded,
                        gradient: AppColors.gradEntree,
                        onTap: () => context.push('/scan?mode=Entrée'),
                      ),
                      BigTile(
                        label: 'SORTIE',
                        icon: Icons.logout_rounded,
                        gradient: AppColors.gradSortie,
                        onTap: () => context.push('/scan?mode=Sortie'),
                      ),
                      BigTile(
                        label: 'CONSULTER',
                        icon: Icons.inventory_2_rounded,
                        gradient: AppColors.gradConsulter,
                        onTap: () => context.push('/stocks'),
                      ),
                      BigTile(
                        label: 'RESPONSABLE',
                        icon: Icons.tune_rounded,
                        gradient: AppColors.gradResponsable,
                        onTap: () {
                          if (op?.estResponsable ?? false) {
                            context.push('/admin');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Réservé au responsable')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
