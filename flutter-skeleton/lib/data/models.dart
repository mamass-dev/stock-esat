/// Modèles de données (simples, sans codegen pour rester lisible).

class Operateur {
  final String id;
  final String nom;
  final String role;
  final String? photoUrl;

  Operateur({required this.id, required this.nom, required this.role, this.photoUrl});

  bool get estResponsable => role == 'responsable' || role == 'admin';
  bool get estAdmin => role == 'admin';

  factory Operateur.fromMap(Map<String, dynamic> m) => Operateur(
        id: m['id'] as String,
        nom: m['nom'] as String,
        role: m['role'] as String,
        photoUrl: m['photo_url'] as String?,
      );
}

class Categorie {
  final String id;
  final String nom;
  Categorie({required this.id, required this.nom});
  factory Categorie.fromMap(Map<String, dynamic> m) =>
      Categorie(id: m['id'] as String, nom: m['nom'] as String);
}

class Site {
  final String id;
  final String nom;
  Site({required this.id, required this.nom});
  factory Site.fromMap(Map<String, dynamic> m) =>
      Site(id: m['id'] as String, nom: m['nom'] as String);
}

class Produit {
  final String id;
  final String ref;
  final String nom;
  final String? photoUrl;
  final String? unite;
  final int stockCourant;
  final int seuilMini;
  final int seuilRupture;
  final int seuilCible;
  final String? categorieId;
  final String? siteId;

  Produit({
    required this.id,
    required this.ref,
    required this.nom,
    this.photoUrl,
    this.unite,
    required this.stockCourant,
    required this.seuilMini,
    required this.seuilRupture,
    this.seuilCible = 0,
    this.categorieId,
    this.siteId,
  });

  factory Produit.fromMap(Map<String, dynamic> m) => Produit(
        id: m['id'] as String,
        ref: m['ref'] as String,
        nom: m['nom'] as String,
        photoUrl: m['photo_url'] as String?,
        unite: m['unite'] as String?,
        stockCourant: (m['stock_courant'] ?? 0) as int,
        seuilMini: (m['seuil_mini'] ?? 0) as int,
        seuilRupture: (m['seuil_rupture'] ?? 0) as int,
        seuilCible: (m['seuil_cible'] ?? 0) as int,
        categorieId: m['categorie_id'] as String?,
        siteId: m['site_id'] as String?,
      );
}
