"use client";

import { useMemo, useState } from "react";
import type { Mouvement } from "@/lib/data";

function fmt(iso: string) {
  return new Date(iso).toLocaleString("fr-FR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function auteur(m: Mouvement): string {
  if (m.operateurs?.nom) return m.operateurs.nom;
  if (m.source === "Web") return "Axel";
  return "—";
}

export default function MouvementsTable({
  mouvements,
}: {
  mouvements: Mouvement[];
}) {
  const [q, setQ] = useState("");
  const [du, setDu] = useState("");
  const [au, setAu] = useState("");

  const liste = useMemo(() => {
    return mouvements.filter((m) => {
      const jour = m.cree_le.slice(0, 10);
      if (du && jour < du) return false;
      if (au && jour > au) return false;
      if (q) {
        const t = q.toLowerCase();
        const hay = `${m.produits?.nom ?? ""} ${auteur(m)} ${m.type}`.toLowerCase();
        if (!hay.includes(t)) return false;
      }
      return true;
    });
  }, [mouvements, q, du, au]);

  return (
    <div>
      <div className="flex flex-wrap gap-3 items-end mb-5">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Rechercher (produit, personne…)"
          className="flex-1 min-w-[200px] px-4 py-2.5 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
        />
        <div>
          <label className="block text-xs text-slate-400 mb-1">Du</label>
          <input
            type="date"
            value={du}
            onChange={(e) => setDu(e.target.value)}
            className="px-3 py-2 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
          />
        </div>
        <div>
          <label className="block text-xs text-slate-400 mb-1">Au</label>
          <input
            type="date"
            value={au}
            onChange={(e) => setAu(e.target.value)}
            className="px-3 py-2 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
          />
        </div>
        {(du || au || q) && (
          <button
            onClick={() => {
              setQ("");
              setDu("");
              setAu("");
            }}
            className="px-4 py-2.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 text-sm"
          >
            Réinitialiser
          </button>
        )}
      </div>

      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-400 border-b border-slate-100">
              <th className="px-5 py-3 font-semibold">Date</th>
              <th className="px-5 py-3 font-semibold">Type</th>
              <th className="px-5 py-3 font-semibold">Produit</th>
              <th className="px-5 py-3 font-semibold">Lieu</th>
              <th className="px-5 py-3 font-semibold">Par qui</th>
              <th className="px-5 py-3 font-semibold text-right">Quantité</th>
              <th className="px-5 py-3 font-semibold text-right">Avant → Après</th>
            </tr>
          </thead>
          <tbody>
            {liste.map((m, i) => {
              const entree = m.type === "Entrée";
              return (
                <tr key={i} className="border-b border-slate-50">
                  <td className="px-5 py-3 text-slate-600 whitespace-nowrap">
                    {fmt(m.cree_le)}
                  </td>
                  <td className="px-5 py-3">
                    <span
                      className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${
                        entree
                          ? "bg-emerald-50 text-emerald-700"
                          : "bg-[#E7EEFB] text-[#2557D6]"
                      }`}
                    >
                      {m.type}
                    </span>
                  </td>
                  <td className="px-5 py-3 font-medium text-slate-800">
                    {m.produits?.nom ?? "—"}
                  </td>
                  <td className="px-5 py-3 text-slate-600 whitespace-nowrap">
                    {m.sites
                      ? `${m.sites.type === "Prestation" ? "🧾" : "📍"} ${m.sites.nom}`
                      : "—"}
                  </td>
                  <td className="px-5 py-3 text-slate-600">{auteur(m)}</td>
                  <td
                    className={`px-5 py-3 text-right font-bold ${
                      entree ? "text-emerald-600" : "text-[#2557D6]"
                    }`}
                  >
                    {entree ? "+" : "−"}
                    {m.quantite}
                  </td>
                  <td className="px-5 py-3 text-right text-slate-400">
                    {m.stock_avant} → {m.stock_apres}
                  </td>
                </tr>
              );
            })}
            {liste.length === 0 && (
              <tr>
                <td colSpan={7} className="px-5 py-10 text-center text-slate-400">
                  Aucun mouvement
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      <p className="text-sm text-slate-400 mt-3">{liste.length} mouvement(s)</p>
    </div>
  );
}
