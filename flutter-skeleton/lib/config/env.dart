/// Configuration Supabase.
/// La clé `anon` est PUBLIQUE (bridée par RLS) — pas de secret ici.
/// ⚠️ Ne JAMAIS mettre la clé `service_role` ni le mot de passe DB dans l'app.
class Env {
  static const String supabaseUrl = 'https://jhxgpzgpbaampmoieusu.supabase.co';

  // Clé `anon` `public` (bridée par RLS — sûre dans l'app).
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpoeGdwemdwYmFhbXBtb2lldXN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI5MTM1NjcsImV4cCI6MjA5ODQ4OTU2N30.AEEM_DfVCcqaMVUhgPYpgRh7_YTCIzqXtdHGVc1YOJE';

  /// Site courant de cette tablette (multi-sites). Laisser null au démarrage
  /// mono-site ; renseigner l'id du site plus tard.
  static const String? siteId = null;
}
