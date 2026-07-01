import "server-only";
import { createClient } from "@supabase/supabase-js";

// Client Supabase PRIVILÉGIÉ (service_role) — SERVEUR UNIQUEMENT.
// À n'utiliser que dans des routes/serveur ayant déjà vérifié la session (isAuthed).
export function sbAdmin() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL ??
      "https://jhxgpzgpbaampmoieusu.supabase.co",
    process.env.SUPABASE_SERVICE_ROLE ?? "",
    { auth: { persistSession: false } }
  );
}
