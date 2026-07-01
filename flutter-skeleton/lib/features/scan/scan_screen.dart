import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/repositories.dart';
import '../sortie/mouvement_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, required this.mode});
  final String mode; // 'Entrée' | 'Sortie'

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _traite = false; // anti double-scan

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_traite) return;
    final code = cap.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    setState(() => _traite = true);
    buzz();

    final produit = await ref.read(produitRepoProvider).parScan(code);
    if (!mounted) return;

    if (produit == null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('❓ Produit inconnu'),
          content: const Text("Je ne connais pas ce code."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Réessayer', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      );
      setState(() => _traite = false);
      return;
    }

    context.pushReplacement('/mouvement',
        extra: MouvementArgs(produit: produit, mode: widget.mode));
  }

  @override
  Widget build(BuildContext context) {
    final estSortie = widget.mode == 'Sortie';
    return Scaffold(
      appBar: AppBar(
        title: Text(estSortie ? '📤 SORTIE' : '📦 ENTRÉE'),
        backgroundColor: estSortie ? AppColors.primary : AppColors.ok,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) => Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(28),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.no_photography_rounded,
                            color: Colors.white, size: 60),
                        SizedBox(height: 16),
                        Text(
                          "Caméra indisponible.\nAutorisez l'accès à la caméra\ndans les réglages du téléphone.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(Dim.pad),
            child: Text('Visez le QR du produit',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
