import ExcelJS from "exceljs";
import { getProduits, aCommander, statut } from "@/lib/data";
import type { Mouvement } from "@/lib/data";
import { isAuthed } from "@/lib/auth";
import { sbAdmin } from "@/lib/admin";

function auteur(m: Mouvement): string {
  if (m.operateurs?.nom) return m.operateurs.nom;
  if (m.source === "Web") return "Axel";
  return "";
}

export const dynamic = "force-dynamic";

const HEADER_FILL: ExcelJS.Fill = {
  type: "pattern",
  pattern: "solid",
  fgColor: { argb: "FF2557D6" },
};

function styliserEntete(ws: ExcelJS.Worksheet) {
  ws.getRow(1).eachCell((c) => {
    c.fill = HEADER_FILL;
    c.font = { bold: true, color: { argb: "FFFFFFFF" } };
  });
  ws.getRow(1).height = 22;
  ws.views = [{ state: "frozen", ySplit: 1 }];
}

const STATUT_FILL: Record<string, string> = {
  ok: "FFE6F6EC",
  faible: "FFFDF0DD",
  rupture: "FFFCE8E8",
};
const STATUT_TXT: Record<string, string> = {
  ok: "🟢 OK",
  faible: "🟠 Faible",
  rupture: "🔴 Rupture",
};

export async function GET() {
  if (!(await isAuthed())) {
    return new Response("Non autorisé", { status: 401 });
  }
  const produits = await getProduits();
  const { data: mvtData } = await sbAdmin()
    .from("mouvements")
    .select(
      "type,quantite,stock_avant,stock_apres,cree_le,source,produits(nom),operateurs(nom)"
    )
    .order("cree_le", { ascending: false })
    .limit(2000);
  const mouvements = (mvtData as unknown as Mouvement[]) ?? [];
  const cmd = aCommander(produits);

  const wb = new ExcelJS.Workbook();
  wb.creator = "Stock'ESAT";

  // Inventaire
  const inv = wb.addWorksheet("Inventaire");
  inv.columns = [
    { header: "Référence", key: "ref", width: 20 },
    { header: "Produit", key: "nom", width: 34 },
    { header: "Catégorie", key: "cat", width: 20 },
    { header: "Site", key: "site", width: 16 },
    { header: "Stock", key: "stock", width: 10 },
    { header: "Unité", key: "unite", width: 12 },
    { header: "Seuil mini", key: "smin", width: 12 },
    { header: "Seuil cible", key: "scible", width: 12 },
    { header: "Statut", key: "statut", width: 14 },
  ];
  for (const p of produits) {
    const s = statut(p);
    const row = inv.addRow({
      ref: p.ref,
      nom: p.nom,
      cat: p.categories?.nom ?? "",
      site: p.sites?.nom ?? "",
      stock: p.stock_courant,
      unite: p.unite ?? "",
      smin: p.seuil_mini,
      scible: p.seuil_cible,
      statut: STATUT_TXT[s],
    });
    row.getCell("statut").fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: STATUT_FILL[s] },
    };
  }
  styliserEntete(inv);

  // À commander
  const wc = wb.addWorksheet("À commander");
  wc.columns = [
    { header: "Produit", key: "nom", width: 34 },
    { header: "Référence", key: "ref", width: 20 },
    { header: "Stock actuel", key: "stock", width: 14 },
    { header: "Seuil cible", key: "scible", width: 12 },
    { header: "Qté à commander", key: "qte", width: 18 },
  ];
  for (const p of cmd) {
    wc.addRow({
      nom: p.nom,
      ref: p.ref,
      stock: p.stock_courant,
      scible: p.seuil_cible,
      qte: p.qte,
    });
  }
  styliserEntete(wc);

  // Historique
  const hist = wb.addWorksheet("Historique");
  hist.columns = [
    { header: "Date", key: "date", width: 20 },
    { header: "Type", key: "type", width: 12 },
    { header: "Produit", key: "nom", width: 34 },
    { header: "Par qui", key: "auteur", width: 22 },
    { header: "Quantité", key: "qte", width: 10 },
    { header: "Stock avant", key: "avant", width: 12 },
    { header: "Stock après", key: "apres", width: 12 },
  ];
  for (const m of mouvements) {
    hist.addRow({
      date: new Date(m.cree_le).toLocaleString("fr-FR"),
      type: m.type,
      nom: m.produits?.nom ?? "",
      auteur: auteur(m),
      qte: m.quantite,
      avant: m.stock_avant,
      apres: m.stock_apres,
    });
  }
  styliserEntete(hist);

  const buf = await wb.xlsx.writeBuffer();
  const d = new Date();
  const stamp = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;

  return new Response(Buffer.from(buf as ArrayBuffer), {
    headers: {
      "Content-Type":
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="Stock-ESAT_${stamp}.xlsx"`,
    },
  });
}
