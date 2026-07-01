import { sb } from "./supabase";

export type Produit = {
  id: string;
  ref: string;
  nom: string;
  stock_courant: number;
  seuil_mini: number;
  seuil_rupture: number;
  seuil_cible: number;
  unite: string | null;
  photo_url: string | null;
  categorie_id: string | null;
  site_id: string | null;
  categories: { nom: string } | null;
  sites: { nom: string } | null;
};

export type Mouvement = {
  type: string;
  quantite: number;
  stock_avant: number | null;
  stock_apres: number | null;
  cree_le: string;
  produits: { nom: string } | null;
  source?: string | null;
  operateurs?: { nom: string } | null;
};

export type Statut = "ok" | "faible" | "rupture";

export function statut(p: Produit): Statut {
  if (p.stock_courant <= p.seuil_rupture) return "rupture";
  if (p.stock_courant <= p.seuil_mini) return "faible";
  return "ok";
}

export async function getProduits(): Promise<Produit[]> {
  const { data } = await sb()
    .from("produits")
    .select(
      "id,ref,nom,stock_courant,seuil_mini,seuil_rupture,seuil_cible,unite,photo_url,categorie_id,site_id,categories(nom),sites(nom)"
    )
    .eq("actif", true)
    .order("nom");
  return (data as unknown as Produit[]) ?? [];
}

export async function getProduitByRef(ref: string): Promise<Produit | null> {
  const { data } = await sb()
    .from("produits")
    .select(
      "id,ref,nom,stock_courant,seuil_mini,seuil_rupture,seuil_cible,unite,photo_url,categorie_id,site_id,categories(nom),sites(nom)"
    )
    .eq("ref", ref)
    .maybeSingle();
  return (data as unknown as Produit) ?? null;
}

export type Ref = { id: string; nom: string };

export async function getCategories(): Promise<Ref[]> {
  const { data } = await sb().from("categories").select("id,nom").order("ordre");
  return (data as Ref[]) ?? [];
}

export async function getSites(): Promise<Ref[]> {
  const { data } = await sb().from("sites").select("id,nom").order("nom");
  return (data as Ref[]) ?? [];
}

export async function getMouvements(limit = 300): Promise<Mouvement[]> {
  const { data } = await sb()
    .from("mouvements")
    .select("type,quantite,stock_avant,stock_apres,cree_le,produits(nom)")
    .order("cree_le", { ascending: false })
    .limit(limit);
  return (data as unknown as Mouvement[]) ?? [];
}

// Agrégats pour le dashboard.
export function agreger(produits: Produit[], mouvements: Mouvement[]) {
  let ok = 0,
    faible = 0,
    rupture = 0,
    unites = 0;
  for (const p of produits) {
    unites += p.stock_courant;
    const s = statut(p);
    if (s === "ok") ok++;
    else if (s === "faible") faible++;
    else rupture++;
  }

  const now = new Date();
  const debutMois = new Date(now.getFullYear(), now.getMonth(), 1);

  // Conso 7 jours
  const conso: { jour: string; sorties: number }[] = [];
  const joursLettres = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
    conso.push({ jour: joursLettres[d.getDay()], sorties: 0 });
  }
  const base = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 6);

  // Top produits du mois
  const map = new Map<string, number>();
  for (const m of mouvements) {
    if (m.type !== "Sortie") continue;
    const d = new Date(m.cree_le);
    if (d >= debutMois) {
      const nom = m.produits?.nom ?? "?";
      map.set(nom, (map.get(nom) ?? 0) + m.quantite);
    }
    const jour = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    const idx = Math.round((jour.getTime() - base.getTime()) / 86400000);
    if (idx >= 0 && idx < 7) conso[idx].sorties += m.quantite;
  }
  const top = [...map.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 6)
    .map(([nom, total]) => ({ nom, total }));

  return {
    totalRefs: produits.length,
    unites,
    ok,
    faible,
    rupture,
    conso,
    top,
  };
}

export function aCommander(produits: Produit[]) {
  return produits
    .filter((p) => p.stock_courant <= p.seuil_mini)
    .sort((a, b) => a.stock_courant - b.stock_courant)
    .map((p) => ({
      ...p,
      qte: Math.max((p.seuil_cible || 0) - p.stock_courant, 0),
    }));
}
