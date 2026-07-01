import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/repositories.dart';

class AdminMenuScreen extends ConsumerWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final op = ref.watch(operateurCourantProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('⚙ RESPONSABLE')),
      body: Padding(
        padding: const EdgeInsets.all(Dim.pad),
        child: Column(
          children: [
            // Ajout de produit : ADMIN uniquement
            if (op?.estAdmin ?? false) ...[
              BigButton(
                label: 'AJOUTER UN PRODUIT',
                icon: Icons.add_box_rounded,
                gradient: AppColors.gradEntree,
                onTap: () => context.push('/admin/produit'),
              ),
              const SizedBox(height: Dim.gap),
              BigButton(
                label: 'GÉRER / SUPPRIMER',
                icon: Icons.edit_note_rounded,
                gradient: AppColors.gradResponsable,
                onTap: () => context.push('/admin/produits'),
              ),
              const SizedBox(height: Dim.gap),
            ],
            BigButton(
              label: 'COCKPIT',
              icon: Icons.dashboard_rounded,
              gradient: AppColors.gradConsulter,
              onTap: () => context.push('/admin/cockpit'),
            ),
            const SizedBox(height: Dim.gap),
            // Export volontairement indisponible sur mobile (réservé à l'ordinateur).
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Dim.radius),
                border: Border.all(color: const Color(0xFFE1E7F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.computer_rounded,
                      color: AppColors.textSoft, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Export Excel : disponible sur l'ordinateur du responsable.",
                      style: TextStyle(fontSize: 15, color: AppColors.textSoft),
                    ),
                  ),
                ],
              ),
            ),
            if (!(op?.estAdmin ?? false)) ...[
              const SizedBox(height: 30),
              const Text(
                "L'ajout de produits est réservé au compte administrateur.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
