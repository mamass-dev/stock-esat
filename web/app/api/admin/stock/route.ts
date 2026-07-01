import { isAuthed } from "@/lib/auth";
import { sbAdmin } from "@/lib/admin";

export async function PATCH(req: Request) {
  if (!(await isAuthed())) return new Response("Non autorisé", { status: 401 });
  const b = await req.json().catch(() => ({}));
  if (!b.stockId || !b.produitId || !b.nom?.trim())
    return Response.json({ error: "Champs requis manquants" }, { status: 400 });
  const { error } = await sbAdmin().rpc("web_modifier_stock", {
    p_stock_id: b.stockId,
    p_produit_id: b.produitId,
    p_nom: b.nom.trim(),
    p_categorie_id: b.categorieId || null,
    p_unite: b.unite?.trim() || null,
    p_seuil_mini: Number(b.seuilMini) || 0,
    p_seuil_cible: Number(b.seuilCible) || 0,
  });
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ ok: true });
}

export async function DELETE(req: Request) {
  if (!(await isAuthed())) return new Response("Non autorisé", { status: 401 });
  const b = await req.json().catch(() => ({}));
  if (!b.stockId) return Response.json({ error: "id requis" }, { status: 400 });
  const { error } = await sbAdmin().rpc("web_supprimer_stock", {
    p_stock_id: b.stockId,
  });
  if (error) return Response.json({ error: error.message }, { status: 400 });
  return Response.json({ ok: true });
}
