import { isAuthed } from "@/lib/auth";
import { sbAdmin } from "@/lib/admin";
import { genererRef } from "@/lib/genRef";

export async function POST(req: Request) {
  if (!(await isAuthed())) return new Response("Non autorisé", { status: 401 });
  const b = await req.json().catch(() => ({}));
  const nom = (b.nom ?? "").trim();
  const ref = genererRef(nom);
  if (!nom || !ref) {
    return Response.json({ error: "Nom requis" }, { status: 400 });
  }
  const { error } = await sbAdmin().rpc("web_creer_produit", {
    p_ref: ref,
    p_nom: nom,
    p_categorie_id: b.categorieId || null,
    p_site_id: b.siteId || null,
    p_unite: b.unite?.trim() || null,
    p_stock: Number(b.stockInitial) || 0,
    p_seuil_mini: Number(b.seuilMini) || 0,
    p_seuil_cible: Number(b.seuilCible) || 0,
    p_photo_url: b.photoUrl || null,
  });
  if (error) {
    const msg = error.message.includes("existe déjà")
      ? `La référence « ${ref} » existe déjà.`
      : error.message;
    return Response.json({ error: msg }, { status: 400 });
  }
  return Response.json({ ok: true, ref });
}

// Modifier un produit (session dashboard, sans PIN)
export async function PATCH(req: Request) {
  if (!(await isAuthed())) return new Response("Non autorisé", { status: 401 });
  const b = await req.json().catch(() => ({}));
  if (!b.id || !b.nom?.trim())
    return Response.json({ error: "id et nom requis" }, { status: 400 });
  const { error } = await sbAdmin().rpc("web_modifier_produit", {
    p_produit_id: b.id,
    p_nom: b.nom.trim(),
    p_categorie_id: b.categorieId || null,
    p_site_id: b.siteId || null,
    p_unite: b.unite?.trim() || null,
    p_seuil_mini: Number(b.seuilMini) || 0,
    p_seuil_cible: Number(b.seuilCible) || 0,
    p_photo_url: null,
  });
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ ok: true });
}

// Supprimer / archiver un produit (session dashboard, sans PIN)
export async function DELETE(req: Request) {
  if (!(await isAuthed())) return new Response("Non autorisé", { status: 401 });
  const b = await req.json().catch(() => ({}));
  if (!b.id) return Response.json({ error: "id requis" }, { status: 400 });
  const { data, error } = await sbAdmin().rpc("web_supprimer_produit", {
    p_produit_id: b.id,
  });
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ ok: true, resultat: data });
}
