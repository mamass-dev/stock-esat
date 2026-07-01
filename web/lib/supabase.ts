import { createClient } from "@supabase/supabase-js";

// Valeurs publiques (URL + clé anon bridée par RLS, lecture seule).
// Fallback en dur pour un déploiement sans friction ; surchargeables via env.
const URL =
  process.env.NEXT_PUBLIC_SUPABASE_URL ??
  "https://jhxgpzgpbaampmoieusu.supabase.co";
const ANON =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpoeGdwemdwYmFhbXBtb2lldXN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI5MTM1NjcsImV4cCI6MjA5ODQ4OTU2N30.AEEM_DfVCcqaMVUhgPYpgRh7_YTCIzqXtdHGVc1YOJE";

export function sb() {
  return createClient(URL, ANON, { auth: { persistSession: false } });
}
