import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/repositories.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
                const SizedBox(height: 18),
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
