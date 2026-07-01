"use client";

import { useMemo, useState } from "react";
import { QRCodeSVG } from "qrcode.react";

export type ProduitEtiquette = {
  id: string;
  ref: string;
  nom: string;
  site: string | null;
};

export default function EtiquettesPlanche({
  produits,
}: {
  produits: ProduitEtiquette[];
}) {
  const [sel, setSel] = useState<Set<string>>(new Set());
  const [q, setQ] = useState("");
  const [copies, setCopies] = useState(1);

  const liste = useMemo(
    () =>
      produits.filter(
        (p) => !q || p.nom.toLowerCase().includes(q.toLowerCase())
      ),
    [produits, q]
  );

  function toggle(id: string) {
    setSel((prev) => {
      const n = new Set(prev);
      if (n.has(id)) n.delete(id);
      else n.add(id);
      return n;
    });
  }
  function toutSelectionner() {
    setSel(new Set(liste.map((p) => p.id)));
  }
  function toutDeselectionner() {
    setSel(new Set());
  }

  const aImprimer = produits.filter((p) => sel.has(p.id));
  const etiquettes = aImprimer.flatMap((p) =>
    Array.from({ length: Math.max(1, copies) }, () => p)
  );

  return (
    <div>
      {/* Contrôles (non imprimés) */}
      <div className="no-print">
        <div className="flex flex-wrap gap-3 items-end mb-4">
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Rechercher un produit…"
            className="flex-1 min-w-[200px] px-4 py-2.5 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
          />
          <div>
            <label className="block text-xs text-slate-400 mb-1">
              Exemplaires / produit
            </label>
            <input
              type="number"
              min={1}
              max={40}
              value={copies}
              onChange={(e) =>
                setCopies(Math.min(40, Math.max(1, Number(e.target.value) || 1)))
              }
              className="w-24 px-3 py-2 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
            />
          </div>
          <button
            onClick={toutSelectionner}
            className="px-4 py-2.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 text-sm"
          >
            Tout sélectionner
          </button>
          {sel.size > 0 && (
            <button
              onClick={toutDeselectionner}
              className="px-4 py-2.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 text-sm"
            >
              Vider
            </button>
          )}
          <button
            onClick={() => window.print()}
            disabled={sel.size === 0}
            className="ml-auto px-5 py-2.5 rounded-xl bg-[#2557D6] hover:bg-[#1e4bb8] text-white font-semibold disabled:opacity-50"
          >
            🖨️ Imprimer ({etiquettes.length})
          </button>
        </div>

        {/* Liste de sélection */}
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden max-h-[420px] overflow-y-auto">
          {liste.map((p) => (
            <label
              key={p.id}
              className="flex items-center gap-3 px-5 py-2.5 border-b border-slate-50 cursor-pointer hover:bg-slate-50"
            >
              <input
                type="checkbox"
                checked={sel.has(p.id)}
                onChange={() => toggle(p.id)}
                className="w-4 h-4 accent-[#2557D6]"
              />
              <span className="font-medium text-slate-800">{p.nom}</span>
              <span className="text-xs text-slate-400">{p.ref}</span>
            </label>
          ))}
          {liste.length === 0 && (
            <p className="px-5 py-8 text-center text-slate-400">Aucun produit</p>
          )}
        </div>
        <p className="text-sm text-slate-400 mt-3">
          {sel.size} produit(s) sélectionné(s) · {etiquettes.length} étiquette(s)
          à imprimer
        </p>
      </div>

      {/* Planche imprimable A4 */}
      <div className="planche">
        {etiquettes.map((p, i) => (
          <div key={i} className="etq">
            <QRCodeSVG value={`P:${p.ref}`} size={78} />
            <div className="etq-txt">
              <div className="etq-nom">{p.nom}</div>
              <div className="etq-ref">{p.ref}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
