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
  sites?: { nom: string; type: string } | null;
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

export type Lieu = { id: string; nom: string; type: string };

// Une ligne de stock = un produit à un lieu précis.
export type StockLigne = {
  id: string;
  produit_id: string;
  ref: string;
  nom: string;
  photo_url: string | null;
  unite: string | null;
  categorie_id: string | null;
  categorie_nom: string | null;
  site_id: string;
  site_nom: string;
  site_type: string;
  stock_courant: number;
  seuil_mini: number;
  seuil_rupture: number;
  seuil_cible: number;
};

type StockRow = {
  id: string;
  stock_courant: number;
  seuil_mini: number;
  seuil_rupture: number;
  seuil_cible: number;
  site_id: string;
  produits: {
    id: string;
    ref: string;
    nom: string;
    photo_url: string | null;
    unite: string | null;
    categorie_id: string | null;
    actif: boolean;
    categories: { nom: string } | null;
  } | null;
  sites: { nom: string; type: string } | null;
};

export async function getStocks(): Promise<StockLigne[]> {
  const { data } = await sb()
    .from("stocks")
    .select(
      "id,stock_courant,seuil_mini,seuil_rupture,seuil_cible,site_id,produits(id,ref,nom,photo_url,unite,categorie_id,actif,categories(nom)),sites(nom,type)"
    );
  const rows = (data as unknown as StockRow[]) ?? [];
  return rows
    .filter((r) => r.produits && r.produits.actif !== false)
    .map((r) => ({
      id: r.id,
      produit_id: r.produits!.id,
      ref: r.produits!.ref,
      nom: r.produits!.nom,
      photo_url: r.produits!.photo_url,
      unite: r.produits!.unite,
      categorie_id: r.produits!.categorie_id,
      categorie_nom: r.produits!.categories?.nom ?? null,
      site_id: r.site_id,
      site_nom: r.sites?.nom ?? "—",
      site_type: r.sites?.type ?? "Site",
      stock_courant: r.stock_courant,
      seuil_mini: r.seuil_mini,
      seuil_rupture: r.seuil_rupture,
      seuil_cible: r.seuil_cible,
    }))
    .sort((a, b) => a.nom.localeCompare(b.nom));
}

export async function getSites(): Promise<Lieu[]> {
  const { data } = await sb()
    .from("sites")
    .select("id,nom,type")
    .order("type")
    .order("nom");
  return (data as Lieu[]) ?? [];
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

// ── Agrégations basées sur le stock PAR LIEU ──
export function agregerStocks(stocks: StockLigne[]) {
  let ok = 0,
    faible = 0,
    rupture = 0,
    unites = 0;
  const refs = new Set<string>();
  for (const s of stocks) {
    refs.add(s.produit_id);
    unites += s.stock_courant;
    if (s.stock_courant <= s.seuil_rupture) rupture++;
    else if (s.stock_courant <= s.seuil_mini) faible++;
    else ok++;
  }
  return { refs: refs.size, lignes: stocks.length, unites, ok, faible, rupture };
}

export function agregerMouvements(mouvements: Mouvement[]) {
  const now = new Date();
  const debutMois = new Date(now.getFullYear(), now.getMonth(), 1);
  const conso: { jour: string; sorties: number }[] = [];
  const jl = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
    conso.push({ jour: jl[d.getDay()], sorties: 0 });
  }
  const base = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 6);
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
  return { conso, top };
}

export function aCommanderStocks(stocks: StockLigne[]) {
  return stocks
    .filter((s) => s.stock_courant <= s.seuil_mini)
    .sort((a, b) => a.stock_courant - b.stock_courant)
    .map((s) => ({ ...s, qte: Math.max((s.seuil_cible || 0) - s.stock_courant, 0) }));
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
