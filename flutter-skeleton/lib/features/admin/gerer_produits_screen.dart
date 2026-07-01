import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';

class GererProduitsScreen extends ConsumerStatefulWidget {
  const GererProduitsScreen({super.key});
  @override
  ConsumerState<GererProduitsScreen> createState() => _State();
}

class _State extends ConsumerState<GererProduitsScreen> {
  List<Produit>? _items;
  String? _erreur;
  String? _suppression; // id en cours de suppression

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final l = await ref.read(produitRepoProvider).tous();
      if (mounted) setState(() => _items = l);
    } catch (e) {
      if (mounted) setState(() => _erreur = '$e');
    }
  }

  Future<void> _supprimer(Produit p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dim.radius)),
        title: const Text('Supprimer ce produit ?'),
        content: Text(
            '« ${p.nom} ».\nS\'il a un historique, il sera archivé (historique conservé).',
            style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler', style: TextStyle(fontSize: 16))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rupture),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final pin = ref.read(sessionPinProvider);
    if (pin == null) {
      _snack('Session expirée, reconnectez-vous.', erreur: true);
      return;
    }
    setState(() => _suppression = p.id);
    try {
      final res = await ref
          .read(produitRepoProvider)
          .supprimerAdmin(pin: pin, produitId: p.id);
      if (!mounted) return;
      buzzSuccess();
      setState(() {
        _items!.removeWhere((x) => x.id == p.id);
        _suppression = null;
      });
      _snack(res == 'archivé'
          ? '« ${p.nom} » archivé (historique conservé)'
          : '« ${p.nom} » supprimé');
    } catch (e) {
      if (!mounted) return;
      setState(() => _suppression = null);
      _snack('Suppression impossible : $e', erreur: true);
    }
  }

  Future<void> _modifier(Produit p) async {
    final maj = await context.push<Produit>('/admin/modifier', extra: p);
    if (maj != null && mounted) {
      setState(() {
        final i = _items!.indexWhere((x) => x.id == p.id);
        if (i != -1) _items![i] = maj;
      });
      _snack('« ${maj.nom} » modifié');
    }
  }

  void _snack(String msg, {bool erreur = false}) {
    if (erreur) buzz(200);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 15)),
      backgroundColor: erreur ? AppColors.rupture : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gérer les produits')),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: _erreur != null
              ? Center(child: Text('Erreur : $_erreur'))
              : _items == null
                  ? const Center(child: CircularProgressIndicator())
                  : _items!.isEmpty
                      ? const Center(
                          child: Text('Aucun produit',
                              style: TextStyle(
                                  fontSize: 18, color: AppColors.textSoft)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(Dim.pad),
                          itemCount: _items!.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _carte(_items![i]),
                        ),
        ),
      ),
    );
  }

  Widget _carte(Produit p) {
    final enCours = _suppression == p.id;
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
              width: 56,
              height: 56,
              child: p.photoUrl != null
                  ? CachedNetworkImage(imageUrl: p.photoUrl!, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFEEF1F7),
                      child: const Icon(Icons.inventory_2_rounded,
                          size: 28, color: AppColors.textSoft)),
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
                        fontSize: 17, fontWeight: FontWeight.w600)),
                Text('Stock : ${p.stockCourant}',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSoft)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          if (enCours)
            const SizedBox(
              width: 44,
              height: 44,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            )
          else ...[
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFE7EEFB),
                padding: const EdgeInsets.all(10),
              ),
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 24),
              onPressed: () => _modifier(p),
            ),
            const SizedBox(width: 6),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.ruptureBg,
                padding: const EdgeInsets.all(10),
              ),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.rupture, size: 24),
              onPressed: () => _supprimer(p),
            ),
          ],
        ],
      ),
    );
  }
}
