import ExcelJS from "exceljs";
import {
  getStocks,
  aCommanderStocks,
  agregerStocks,
  agregerMouvements,
} from "@/lib/data";
import type { Mouvement, StockLigne } from "@/lib/data";
import { isAuthed } from "@/lib/auth";
import { sbAdmin } from "@/lib/admin";

export const dynamic = "force-dynamic";

function statutStock(s: StockLigne): "ok" | "faible" | "rupture" {
  if (s.stock_courant <= s.seuil_rupture) return "rupture";
  if (s.stock_courant <= s.seuil_mini) return "faible";
  return "ok";
}

const BLEU = "FF2557D6";
const HEADER_FILL: ExcelJS.Fill = {
  type: "pattern",
  pattern: "solid",
  fgColor: { argb: BLEU },
};
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

function styliserEntete(ws: ExcelJS.Worksheet) {
  ws.getRow(1).eachCell((c) => {
    c.fill = HEADER_FILL;
    c.font = { bold: true, color: { argb: "FFFFFFFF" } };
    c.alignment = { vertical: "middle" };
  });
  ws.getRow(1).height = 22;
  ws.views = [{ state: "frozen", ySplit: 1 }];
}

function auteur(m: Mouvement): string {
  if (m.operateurs?.nom) return m.operateurs.nom;
  if (m.source === "Web") return "Axel";
  return "";
}

// Graphique -> PNG via QuickChart (échec silencieux si indisponible).
async function chartPng(
  config: unknown,
  width: number,
  height: number
): Promise<ArrayBuffer | null> {
  try {
    const res = await fetch("https://quickchart.io/chart", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chart: config,
        width,
        height,
        backgroundColor: "white",
        format: "png",
        version: "4",
        devicePixelRatio: 2,
      }),
    });
    if (!res.ok) return null;
    return await res.arrayBuffer();
  } catch {
    return null;
  }
}

export async function GET() {
  if (!(await isAuthed())) {
    return new Response("Non autorisé", { status: 401 });
  }

  const stocks = await getStocks();
  const { data: mvtData } = await sbAdmin()
    .from("mouvements")
    .select(
      "type,quantite,stock_avant,stock_apres,cree_le,source,produits(nom),operateurs(nom),sites(nom,type)"
    )
    .order("cree_le", { ascending: false })
    .limit(3000);
  const mouvements = (mvtData as unknown as Mouvement[]) ?? [];
  const cmd = aCommanderStocks(stocks);
  const st = agregerStocks(stocks);
  const a = agregerMouvements(mouvements);

  // Consommation par produit (ce mois), complète
  const now = new Date();
  const debutMois = new Date(now.getFullYear(), now.getMonth(), 1);
  const consoMap = new Map<string, number>();
  for (const m of mouvements) {
    if (m.type !== "Sortie") continue;
    if (new Date(m.cree_le) < debutMois) continue;
    const nom = m.produits?.nom ?? "?";
    consoMap.set(nom, (consoMap.get(nom) ?? 0) + m.quantite);
  }
  const conso = [...consoMap.entries()]
    .map(([nom, total]) => ({ nom, total }))
    .sort((x, y) => y.total - x.total);

  const wb = new ExcelJS.Workbook();
  wb.creator = "Stock'ESAT";

  // ══════════ Feuille 1 : Synthèse ══════════
  const syn = wb.addWorksheet("Synthèse", {
    views: [{ showGridLines: false }],
  });
  syn.getColumn(1).width = 26;
  syn.getColumn(2).width = 16;
  syn.mergeCells("A1:E1");
  const titre = syn.getCell("A1");
  titre.value = "Stock'ESAT — Synthèse du stock";
  titre.font = { bold: true, size: 18, color: { argb: BLEU } };
  syn.getCell("A2").value = `Édité le ${now.toLocaleString("fr-FR")}`;
  syn.getCell("A2").font = { italic: true, color: { argb: "FF888888" } };

  const kpis: [string, number, string][] = [
    ["Références actives", st.refs, "FFE7EEFB"],
    ["Unités en stock", st.unites, "FFE7EEFB"],
    ["🔴 Ruptures", st.rupture, "FFFCE8E8"],
    ["🟠 Stocks faibles", st.faible, "FFFDF0DD"],
    ["🟢 Stocks OK", st.ok, "FFE6F6EC"],
  ];
  let r = 4;
  for (const [label, val, fill] of kpis) {
    const cL = syn.getCell(`A${r}`);
    const cV = syn.getCell(`B${r}`);
    cL.value = label;
    cL.font = { bold: true };
    cV.value = val;
    cV.font = { bold: true, size: 14 };
    cV.alignment = { horizontal: "center" };
    for (const c of [cL, cV]) {
      c.fill = { type: "pattern", pattern: "solid", fgColor: { argb: fill } };
      c.border = { bottom: { style: "thin", color: { argb: "FFFFFFFF" } } };
    }
    syn.getRow(r).height = 22;
    r++;
  }

  // Graphiques (images) — échec silencieux si QuickChart indisponible
  const doughnut = await chartPng(
    {
      type: "doughnut",
      data: {
        labels: ["OK", "Faible", "Rupture"],
        datasets: [
          {
            data: [st.ok, st.faible, st.rupture],
            backgroundColor: ["#1E9E5A", "#E8890C", "#E23D3D"],
          },
        ],
      },
      options: {
        plugins: {
          title: { display: true, text: "Répartition du stock" },
          legend: { position: "bottom" },
        },
      },
    },
    360,
    240
  );
  if (doughnut) {
    const id = wb.addImage({ buffer: doughnut, extension: "png" });
    syn.addImage(id, { tl: { col: 3, row: 3 }, ext: { width: 320, height: 210 } });
  }

  const barConso = await chartPng(
    {
      type: "bar",
      data: {
        labels: a.conso.map((c) => c.jour),
        datasets: [
          {
            label: "Sorties",
            data: a.conso.map((c) => c.sorties),
            backgroundColor: "#2557D6",
          },
        ],
      },
      options: {
        plugins: {
          title: { display: true, text: "Consommation (7 derniers jours)" },
          legend: { display: false },
        },
      },
    },
    520,
    240
  );
  if (barConso) {
    const id = wb.addImage({ buffer: barConso, extension: "png" });
    syn.addImage(id, { tl: { col: 0, row: 11 }, ext: { width: 470, height: 210 } });
  }

  const topData = a.top.slice(0, 8);
  const barTop = await chartPng(
    {
      type: "bar",
      data: {
        labels: topData.map((t) => t.nom),
        datasets: [
          {
            label: "Sorties (mois)",
            data: topData.map((t) => t.total),
            backgroundColor: "#6C7BF2",
          },
        ],
      },
      options: {
        indexAxis: "y",
        plugins: {
          title: { display: true, text: "Produits les plus utilisés (ce mois)" },
          legend: { display: false },
        },
      },
    },
    520,
    260
  );
  if (barTop) {
    const id = wb.addImage({ buffer: barTop, extension: "png" });
    syn.addImage(id, { tl: { col: 0, row: 24 }, ext: { width: 470, height: 230 } });
  }

  // ══════════ Feuille 2 : Inventaire ══════════
  const inv = wb.addWorksheet("Inventaire");
  inv.columns = [
    { header: "Référence", key: "ref", width: 20 },
    { header: "Produit", key: "nom", width: 34 },
    { header: "Catégorie", key: "cat", width: 20 },
    { header: "Lieu", key: "site", width: 16 },
    { header: "Stock", key: "stock", width: 10 },
    { header: "Unité", key: "unite", width: 12 },
    { header: "Seuil mini", key: "smin", width: 12 },
    { header: "Seuil cible", key: "scible", width: 12 },
    { header: "Statut", key: "statut", width: 14 },
  ];
  for (const p of stocks) {
    const s = statutStock(p);
    const row = inv.addRow({
      ref: p.ref,
      nom: p.nom,
      cat: p.categorie_nom ?? "",
      site: p.site_nom,
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
  // Barre visuelle dans la colonne Stock (E)
  if (stocks.length > 0) {
    inv.addConditionalFormatting({
      ref: `E2:E${stocks.length + 1}`,
      rules: [
        {
          type: "dataBar",
          gradient: false,
          cfvo: [{ type: "min" }, { type: "max" }],
          color: { argb: "FF9DB8EC" },
        } as unknown as ExcelJS.ConditionalFormattingRule,
      ],
    });
  }
  styliserEntete(inv);

  // ══════════ Feuille 3 : À commander ══════════
  const wc = wb.addWorksheet("À commander");
  wc.columns = [
    { header: "Produit", key: "nom", width: 34 },
    { header: "Lieu", key: "lieu", width: 16 },
    { header: "Référence", key: "ref", width: 20 },
    { header: "Stock actuel", key: "stock", width: 14 },
    { header: "Seuil cible", key: "scible", width: 12 },
    { header: "Qté à commander", key: "qte", width: 18 },
  ];
  for (const p of cmd) {
    wc.addRow({
      nom: p.nom,
      lieu: p.site_nom,
      ref: p.ref,
      stock: p.stock_courant,
      scible: p.seuil_cible,
      qte: p.qte,
    });
  }
  if (cmd.length > 0) {
    wc.addConditionalFormatting({
      ref: `F2:F${cmd.length + 1}`,
      rules: [
        {
          type: "dataBar",
          gradient: false,
          cfvo: [{ type: "min" }, { type: "max" }],
          color: { argb: "FFF2B8B8" },
        } as unknown as ExcelJS.ConditionalFormattingRule,
      ],
    });
  }
  styliserEntete(wc);

  // ══════════ Feuille 4 : Consommation (mois) ══════════
  const cs = wb.addWorksheet("Consommation");
  cs.columns = [
    { header: "Produit", key: "nom", width: 36 },
    { header: "Sorties ce mois", key: "total", width: 16 },
  ];
  for (const c of conso) cs.addRow({ nom: c.nom, total: c.total });
  if (conso.length > 0) {
    cs.addConditionalFormatting({
      ref: `B2:B${conso.length + 1}`,
      rules: [
        {
          type: "dataBar",
          gradient: false,
          cfvo: [{ type: "min" }, { type: "max" }],
          color: { argb: "FF9DB8EC" },
        } as unknown as ExcelJS.ConditionalFormattingRule,
      ],
    });
  }
  styliserEntete(cs);

  // ══════════ Feuille 5 : Historique ══════════
  const hist = wb.addWorksheet("Historique");
  hist.columns = [
    { header: "Date", key: "date", width: 20 },
    { header: "Type", key: "type", width: 12 },
    { header: "Produit", key: "nom", width: 34 },
    { header: "Lieu", key: "lieu", width: 16 },
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
      lieu: m.sites?.nom ?? "",
      auteur: auteur(m),
      qte: m.quantite,
      avant: m.stock_avant,
      apres: m.stock_apres,
    });
  }
  styliserEntete(hist);

  const buf = await wb.xlsx.writeBuffer();
  const d = now;
  const stamp = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;

  return new Response(Buffer.from(buf as ArrayBuffer), {
    headers: {
      "Content-Type":
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="Stock-ESAT_${stamp}.xlsx"`,
    },
  });
}
