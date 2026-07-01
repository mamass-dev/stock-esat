import { isAuthed } from "@/lib/auth";
import { sbAdmin } from "@/lib/admin";

async function guard() {
  return isAuthed();
}

// Créer un opérateur
export async function POST(req: Request) {
  if (!(await guard())) return new Response("Non autorisé", { status: 401 });
  const b = await req.json().catch(() => ({}));
  if (!b.nom?.trim() || !/^\d{4}$/.test(b.pin ?? "")) {
    return Response.json(
      { error: "Nom et PIN à 4 chiffres requis." },
      { status: 400 }
    );
  }
  const { error } = await sbAdmin().rpc("creer_operateur", {
    p_nom: b.nom.trim(),
    p_pin: b.pin,
    p_role: b.role || "operateur",
  });
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ ok: true });
}

// Modifier un opérateur (nom, rôle, actif, PIN optionnel)
export async function PATCH(req: Request) {
  if (!(await guard())) return new Response("Non autorisé", { status: 401 });
  const b = await req.json().catch(() => ({}));
  if (!b.id) return Response.json({ error: "id requis" }, { status: 400 });
  if (b.pin && !/^\d{4}$/.test(b.pin)) {
    return Response.json(
      { error: "Le PIN doit faire 4 chiffres." },
      { status: 400 }
    );
  }
  const { error } = await sbAdmin().rpc("modifier_operateur", {
    p_id: b.id,
    p_nom: b.nom?.trim() ?? null,
    p_role: b.role ?? null,
    p_actif: typeof b.actif === "boolean" ? b.actif : null,
    p_pin: b.pin || null,
  });
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ ok: true });
}
