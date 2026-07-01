// Stock'ESAT — Export Excel (à lancer sur l'ordinateur du responsable)
// Génère un classeur .xlsx : Inventaire, À commander, Historique.
// Utilise la clé anon (publique, lecture seule via RLS) — aucun secret ici.

import { createClient } from '@supabase/supabase-js';
import ExcelJS from 'exceljs';

const SUPABASE_URL = 'https://jhxgpzgpbaampmoieusu.supabase.co';
const SUPABASE_ANON =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpoeGdwemdwYmFhbXBtb2lldXN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI5MTM1NjcsImV4cCI6MjA5ODQ4OTU2N30.AEEM_DfVCcqaMVUhgPYpgRh7_YTCIzqXtdHGVc1YOJE';

const sb = createClient(SUPABASE_URL, SUPABASE_ANON);

const HEADER_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1D5FA8' } };
const HEADER_FONT = { bold: true, color: { argb: 'FFFFFFFF' } };

function statut(p) {
  if (p.stock_courant <= p.seuil_rupture) return { t: '🔴 Rupture', argb: 'FFFCE8E8' };
  if (p.stock_courant <= p.seuil_mini) return { t: '🟠 Faible', argb: 'FFFDF0DD' };
  return { t: '🟢 OK', argb: 'FFE6F6EC' };
}

function styliserEntete(ws) {
  ws.getRow(1).eachCell((c) => {
    c.fill = HEADER_FILL;
    c.font = HEADER_FONT;
    c.alignment = { vertical: 'middle' };
  });
  ws.getRow(1).height = 22;
  ws.views = [{ state: 'frozen', ySplit: 1 }];
}

async function main() {
  console.log('Connexion et récupération des données…');

  const { data: produits, error: e1 } = await sb
    .from('produits')
    .select('ref,nom,stock_courant,seuil_mini,seuil_cible,unite,categories(nom),sites(nom)')
    .order('nom');
  if (e1) throw e1;

  const { data: mouvements, error: e2 } = await sb
    .from('mouvements')
    .select('type,quantite,stock_avant,stock_apres,cree_le,produits(nom)')
    .order('cree_le', { ascending: false })
    .limit(2000);
  if (e2) throw e2;

  const wb = new ExcelJS.Workbook();
  wb.creator = "Stock'ESAT";

  // ───── Feuille 1 : Inventaire ─────
  const inv = wb.addWorksheet('Inventaire');
  inv.columns = [
    { header: 'Référence', key: 'ref', width: 20 },
    { header: 'Produit', key: 'nom', width: 34 },
    { header: 'Catégorie', key: 'cat', width: 20 },
    { header: 'Site', key: 'site', width: 16 },
    { header: 'Stock', key: 'stock', width: 10 },
    { header: 'Unité', key: 'unite', width: 12 },
    { header: 'Seuil mini', key: 'smin', width: 12 },
    { header: 'Seuil cible', key: 'scible', width: 12 },
    { header: 'Statut', key: 'statut', width: 14 },
  ];
  for (const p of produits) {
    const s = statut(p);
    const row = inv.addRow({
      ref: p.ref, nom: p.nom,
      cat: p.categories?.nom ?? '', site: p.sites?.nom ?? '',
      stock: p.stock_courant, unite: p.unite ?? '',
      smin: p.seuil_mini, scible: p.seuil_cible, statut: s.t,
    });
    row.getCell('statut').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: s.argb } };
  }
  styliserEntete(inv);

  // ───── Feuille 2 : À commander ─────
  const cmd = wb.addWorksheet('À commander');
  cmd.columns = [
    { header: 'Produit', key: 'nom', width: 34 },
    { header: 'Référence', key: 'ref', width: 20 },
    { header: 'Stock actuel', key: 'stock', width: 14 },
    { header: 'Seuil cible', key: 'scible', width: 12 },
    { header: 'Qté à commander', key: 'qte', width: 18 },
  ];
  const aCommander = produits
    .filter((p) => p.stock_courant <= p.seuil_mini)
    .sort((a, b) => a.stock_courant - b.stock_courant);
  for (const p of aCommander) {
    cmd.addRow({
      nom: p.nom, ref: p.ref, stock: p.stock_courant,
      scible: p.seuil_cible,
      qte: Math.max((p.seuil_cible || 0) - p.stock_courant, 0),
    });
  }
  styliserEntete(cmd);

  // ───── Feuille 3 : Historique ─────
  const hist = wb.addWorksheet('Historique');
  hist.columns = [
    { header: 'Date', key: 'date', width: 20 },
    { header: 'Type', key: 'type', width: 12 },
    { header: 'Produit', key: 'nom', width: 34 },
    { header: 'Quantité', key: 'qte', width: 10 },
    { header: 'Stock avant', key: 'avant', width: 12 },
    { header: 'Stock après', key: 'apres', width: 12 },
  ];
  for (const m of mouvements) {
    const d = new Date(m.cree_le);
    hist.addRow({
      date: d.toLocaleString('fr-FR'),
      type: m.type,
      nom: m.produits?.nom ?? '',
      qte: m.quantite,
      avant: m.stock_avant,
      apres: m.stock_apres,
    });
  }
  styliserEntete(hist);

  // ───── Enregistrement ─────
  const d = new Date();
  const stamp = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  const fichier = `Stock-ESAT_${stamp}.xlsx`;
  await wb.xlsx.writeFile(fichier);

  console.log(`\n✅ Export terminé : ${fichier}`);
  console.log(`   • Inventaire : ${produits.length} produits`);
  console.log(`   • À commander : ${aCommander.length} produits`);
  console.log(`   • Historique : ${mouvements.length} mouvements`);
}

main().catch((e) => {
  console.error('❌ Erreur :', e.message);
  process.exit(1);
});
