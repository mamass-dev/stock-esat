import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

final _sb = Supabase.instance.client;
const _uuid = Uuid();
final _picker = ImagePicker();
const _bucketPhotos = 'produits-photos';

/// Prend une photo compressée avec la caméra. Renvoie les octets (ou null si annulé).
Future<Uint8List?> _capturerPhotoCompressee() async {
  final x = await _picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1200, // redimensionne -> ~150-250 Ko
    imageQuality: 70, // compression JPEG
  );
  if (x == null) return null;
  return x.readAsBytes();
}

/// Opérateur connecté (session locale).
final operateurCourantProvider = StateProvider<Operateur?>((ref) => null);

/// PIN de la session (en mémoire uniquement) — sert aux actions admin
/// qui doivent être re-vérifiées côté base (ex. ajout de produit).
final sessionPinProvider = StateProvider<String?>((ref) => null);

/// Lieu courant (site ou prestation) choisi par l'opérateur.
/// Tous les mouvements et la consultation portent sur ce lieu.
final sessionLieuProvider = StateProvider<Site?>((ref) => null);

/// Liste des lieux (sites + prestations).
final lieuxProvider =
    FutureProvider<List<Site>>((ref) => ref.read(produitRepoProvider).sites());

/// Stocks du lieu courant (vide si aucun lieu choisi).
final stocksLieuProvider = FutureProvider.autoDispose<List<Produit>>((ref) {
  final lieu = ref.watch(sessionLieuProvider);
  if (lieu == null) return Future.value(<Produit>[]);
  return ref.read(produitRepoProvider).stocksPourLieu(lieu.id);
});

/// ── Auth par PIN (RPC login_operateur) ──
class AuthRepository {
  Future<Operateur?> loginParPin(String pin) async {
    final res = await _sb.rpc('login_operateur', params: {'p_pin': pin});
    final list = (res as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    return Operateur.fromMap(list.first);
  }
}

final authRepoProvider = Provider((ref) => AuthRepository());

/// ── Produits ──
class ProduitRepository {
  /// Résout le payload d'un QR ("P:DET-SOL-5L") ou une réf brute.
  Future<Produit?> parScan(String payload) async {
    final ref = payload.startsWith('P:') ? payload.substring(2) : payload;
    final row = await _sb
        .from('produits')
        .select()
        .eq('ref', ref)
        .eq('actif', true)
        .maybeSingle();
    return row == null ? null : Produit.fromMap(row);
  }

  Future<Produit> parId(String id) async {
    final row = await _sb.from('produits').select().eq('id', id).single();
    return Produit.fromMap(row);
  }

  // Produit avec le stock/seuils d'un LIEU précis (à partir d'une ligne stocks).
  Produit _fromStock(Map<String, dynamic> row) {
    final p = row['produits'] as Map<String, dynamic>;
    return Produit(
      id: p['id'] as String,
      ref: p['ref'] as String,
      nom: p['nom'] as String,
      photoUrl: p['photo_url'] as String?,
      unite: p['unite'] as String?,
      categorieId: p['categorie_id'] as String?,
      stockCourant: (row['stock_courant'] ?? 0) as int,
      seuilMini: (row['seuil_mini'] ?? 0) as int,
      seuilRupture: (row['seuil_rupture'] ?? 0) as int,
      seuilCible: (row['seuil_cible'] ?? 0) as int,
    );
  }

  /// Stocks d'un lieu (produits présents à ce lieu, avec leur quantité).
  Future<List<Produit>> stocksPourLieu(String siteId) async {
    final rows = await _sb
        .from('stocks')
        .select(
            'stock_courant,seuil_mini,seuil_rupture,seuil_cible,produits(id,ref,nom,photo_url,unite,categorie_id,actif)')
        .eq('site_id', siteId);
    return (rows as List)
        .where((e) => (e['produits']?['actif'] ?? true) == true)
        .map((e) => _fromStock(e))
        .toList()
      ..sort((a, b) => a.nom.compareTo(b.nom));
  }

  /// Résout un scan pour un LIEU : renvoie le produit avec son stock à ce lieu
  /// (0 si pas encore de stock à ce lieu). Null si le code est inconnu.
  Future<Produit?> parScanLieu(String payload, String siteId) async {
    final ref = payload.startsWith('P:') ? payload.substring(2) : payload;
    final prod = await _sb
        .from('produits')
        .select('id,ref,nom,photo_url,unite,categorie_id')
        .eq('ref', ref)
        .eq('actif', true)
        .maybeSingle();
    if (prod == null) return null;
    final st = await _sb
        .from('stocks')
        .select('stock_courant,seuil_mini,seuil_rupture,seuil_cible')
        .eq('produit_id', prod['id'])
        .eq('site_id', siteId)
        .maybeSingle();
    return Produit(
      id: prod['id'] as String,
      ref: prod['ref'] as String,
      nom: prod['nom'] as String,
      photoUrl: prod['photo_url'] as String?,
      unite: prod['unite'] as String?,
      categorieId: prod['categorie_id'] as String?,
      stockCourant: (st?['stock_courant'] ?? 0) as int,
      seuilMini: (st?['seuil_mini'] ?? 0) as int,
      seuilRupture: (st?['seuil_rupture'] ?? 0) as int,
      seuilCible: (st?['seuil_cible'] ?? 0) as int,
    );
  }

  /// Stock d'un produit à un lieu (après un mouvement) — pour rafraîchir.
  Future<Produit> parIdLieu(String produitId, String siteId) async {
    final prod = await _sb
        .from('produits')
        .select('id,ref,nom,photo_url,unite,categorie_id')
        .eq('id', produitId)
        .single();
    final st = await _sb
        .from('stocks')
        .select('stock_courant,seuil_mini,seuil_rupture,seuil_cible')
        .eq('produit_id', produitId)
        .eq('site_id', siteId)
        .maybeSingle();
    return Produit(
      id: prod['id'] as String,
      ref: prod['ref'] as String,
      nom: prod['nom'] as String,
      photoUrl: prod['photo_url'] as String?,
      unite: prod['unite'] as String?,
      categorieId: prod['categorie_id'] as String?,
      stockCourant: (st?['stock_courant'] ?? 0) as int,
      seuilMini: (st?['seuil_mini'] ?? 0) as int,
      seuilRupture: (st?['seuil_rupture'] ?? 0) as int,
      seuilCible: (st?['seuil_cible'] ?? 0) as int,
    );
  }

  Future<List<Produit>> tous() async {
    final rows =
        await _sb.from('produits').select().eq('actif', true).order('nom');
    return (rows as List).map((e) => Produit.fromMap(e)).toList();
  }

  /// ADMIN : modifie un produit existant (pas le stock, pas la réf).
  Future<Produit> modifierAdmin({
    required String pin,
    required String produitId,
    required String nom,
    String? categorieId,
    String? siteId,
    String? unite,
    required int seuilMini,
    required int seuilCible,
    String? photoUrl,
  }) async {
    final res = await _sb.rpc('admin_modifier_produit', params: {
      'p_pin': pin,
      'p_produit_id': produitId,
      'p_nom': nom,
      'p_categorie_id': categorieId,
      'p_site_id': siteId,
      'p_unite': unite,
      'p_seuil_mini': seuilMini,
      'p_seuil_cible': seuilCible,
      'p_photo_url': photoUrl,
    });
    final map = res is List ? res.first : res;
    return Produit.fromMap(map as Map<String, dynamic>);
  }

  /// ADMIN : supprime (ou archive si historique) un produit. La base vérifie le PIN + rôle.
  /// Renvoie 'supprimé' ou 'archivé'.
  Future<String> supprimerAdmin({
    required String pin,
    required String produitId,
  }) async {
    final res = await _sb.rpc('admin_supprimer_produit',
        params: {'p_pin': pin, 'p_produit_id': produitId});
    return res as String;
  }

  /// OPÉRATEUR : prend une photo et la rattache à un produit existant.
  /// Upload dans Storage + RPC qui met à jour photo_url. Renvoie la nouvelle URL.
  Future<String?> capturerEtDefinirPhoto(String produitId) async {
    final bytes = await _capturerPhotoCompressee();
    if (bytes == null) return null;
    final path = '$produitId.jpg';
    await _sb.storage.from(_bucketPhotos).uploadBinary(
          path, bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    // URL publique + anti-cache (pour rafraîchir l'affichage après remplacement)
    final url = _sb.storage.from(_bucketPhotos).getPublicUrl(path);
    final urlFinale = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    await _sb.rpc('definir_photo_produit',
        params: {'p_produit_id': produitId, 'p_photo_url': urlFinale});
    return urlFinale;
  }

  /// ADMIN : prend une photo à la création (aucun id encore) -> renvoie l'URL.
  Future<String?> capturerPhotoNouvelle() async {
    final bytes = await _capturerPhotoCompressee();
    if (bytes == null) return null;
    final path = '${_uuid.v4()}.jpg';
    await _sb.storage.from(_bucketPhotos).uploadBinary(
          path, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return _sb.storage.from(_bucketPhotos).getPublicUrl(path);
  }

  Future<List<Categorie>> categories() async {
    final rows = await _sb.from('categories').select('id,nom').order('ordre');
    return (rows as List).map((e) => Categorie.fromMap(e)).toList();
  }

  Future<List<Site>> sites() async {
    final rows =
        await _sb.from('sites').select('id,nom,type').order('type').order('nom');
    return (rows as List).map((e) => Site.fromMap(e)).toList();
  }

  /// Ajout de produit — RÉSERVÉ ADMIN. La base vérifie le PIN + le rôle.
  /// Lève une exception (message serveur) si non-admin.
  Future<Produit> ajouterAdmin({
    required String pin,
    required String ref,
    required String nom,
    String? categorieId,
    String? siteId,
    String? unite,
    double prix = 0,
    int stockInitial = 0,
    int seuilMini = 0,
    int seuilCible = 0,
    String? photoUrl,
  }) async {
    final res = await _sb.rpc('admin_ajouter_produit', params: {
      'p_pin': pin,
      'p_ref': ref,
      'p_nom': nom,
      'p_categorie_id': categorieId,
      'p_site_id': siteId,
      'p_unite': unite,
      'p_prix': prix,
      'p_stock_initial': stockInitial,
      'p_seuil_mini': seuilMini,
      'p_seuil_cible': seuilCible,
      'p_photo_url': photoUrl,
    });
    // La fonction renvoie la ligne produit créée.
    final map = res is List ? res.first : res;
    return Produit.fromMap(map as Map<String, dynamic>);
  }
}

final produitRepoProvider = Provider((ref) => ProduitRepository());

/// ── Mouvements ──
class MouvementRepository {
  /// Derniers mouvements (avec le nom du produit via jointure).
  Future<List<Map<String, dynamic>>> derniers({int limit = 8}) async {
    final rows = await _sb
        .from('mouvements')
        .select('type, quantite, cree_le, produits(nom)')
        .order('cree_le', ascending: false)
        .limit(limit);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Sorties depuis une date (pour conso & top produits).
  Future<List<Map<String, dynamic>>> sortiesDepuis(DateTime since) async {
    final rows = await _sb
        .from('mouvements')
        .select('quantite, cree_le, produits(nom)')
        .eq('type', 'Sortie')
        .gte('cree_le', since.toIso8601String());
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Insère un mouvement. Le trigger SQL met à jour le stock.
  /// [clientKey] garantit l'idempotence (offline / renvoi).
  Future<void> enregistrer({
    required String type, // 'Entrée' | 'Sortie'
    required String produitId,
    required int quantite,
    String? siteId, // lieu courant
    String? operateurId,
    String source = 'Scan',
  }) async {
    await _sb.from('mouvements').insert({
      'type': type,
      'produit_id': produitId,
      'site_id': siteId,
      'quantite': quantite,
      'operateur_id': operateurId,
      'client_key': _uuid.v4(),
      'source': source,
    });
  }
}

final mouvementRepoProvider = Provider((ref) => MouvementRepository());
