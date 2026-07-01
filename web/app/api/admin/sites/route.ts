import { isAuthed } from "@/lib/auth";
import { sbAdmin } from "@/lib/admin";

export async function POST(req: Request) {
  if (!(await isAuthed())) return new Response("Non autorisé", { status: 401 });
  const b = await req.json().catch(() => ({}));
  if (!b.nom?.trim())
    return Response.json({ error: "Nom requis" }, { status: 400 });
  const { error } = await sbAdmin()
    .from("sites")
    .insert({ nom: b.nom.trim(), ville: b.ville?.trim() || null });
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ ok: true });
}

export async function PATCH(req: Request) {
  if (!(await isAuthed())) return new Response("Non autorisé", { status: 401 });
  const b = await req.json().catch(() => ({}));
  if (!b.id || !b.nom?.trim())
    return Response.json({ error: "id et nom requis" }, { status: 400 });
  const { error } = await sbAdmin()
    .from("sites")
    .update({ nom: b.nom.trim() })
    .eq("id", b.id);
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ ok: true });
}

export async function DELETE(req: Request) {
  if (!(await isAuthed())) return new Response("Non autorisé", { status: 401 });
  const b = await req.json().catch(() => ({}));
  if (!b.id) return Response.json({ error: "id requis" }, { status: 400 });
  const admin = sbAdmin();
  await admin.from("produits").update({ site_id: null }).eq("site_id", b.id);
  await admin.from("operateurs").update({ site_id: null }).eq("site_id", b.id);
  const { error } = await admin.from("sites").delete().eq("id", b.id);
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ ok: true });
}
