"use client";

import { useMemo, useState } from "react";

export type EntreeJournal = {
  action: string;
  produit_ref: string | null;
  produit_nom: string | null;
  details: string | null;
  acteur: string | null;
  cree_le: string;
};

const BADGE: Record<string, string> = {
  Création: "bg-emerald-50 text-emerald-700",
  Modification: "bg-[#E7EEFB] text-[#2557D6]",
  Archivage: "bg-amber-50 text-amber-700",
  Suppression: "bg-red-50 text-red-700",
};

function fmt(iso: string) {
  return new Date(iso).toLocaleString("fr-FR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default function JournalTable({
  entrees,
}: {
  entrees: EntreeJournal[];
}) {
  const [q, setQ] = useState("");
  const [du, setDu] = useState("");
  const [au, setAu] = useState("");

  const liste = useMemo(() => {
    return entrees.filter((e) => {
      const jour = e.cree_le.slice(0, 10);
      if (du && jour < du) return false;
      if (au && jour > au) return false;
      if (q) {
        const t = q.toLowerCase();
        const hay = `${e.produit_nom ?? ""} ${e.acteur ?? ""} ${e.action}`.toLowerCase();
        if (!hay.includes(t)) return false;
      }
      return true;
    });
  }, [entrees, q, du, au]);

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
              <th className="px-5 py-3 font-semibold">Date & heure</th>
              <th className="px-5 py-3 font-semibold">Action</th>
              <th className="px-5 py-3 font-semibold">Produit</th>
              <th className="px-5 py-3 font-semibold">Par qui</th>
              <th className="px-5 py-3 font-semibold">Détails</th>
            </tr>
          </thead>
          <tbody>
            {liste.map((e, i) => (
              <tr key={i} className="border-b border-slate-50">
                <td className="px-5 py-3 text-slate-600 whitespace-nowrap">
                  {fmt(e.cree_le)}
                </td>
                <td className="px-5 py-3">
                  <span
                    className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${
                      BADGE[e.action] ?? "bg-slate-100 text-slate-600"
                    }`}
                  >
                    {e.action}
                  </span>
                </td>
                <td className="px-5 py-3">
                  <span className="font-medium text-slate-800">
                    {e.produit_nom ?? "—"}
                  </span>
                  {e.produit_ref && (
                    <span className="text-xs text-slate-400"> · {e.produit_ref}</span>
                  )}
                </td>
                <td className="px-5 py-3 text-slate-600">{e.acteur ?? "—"}</td>
                <td className="px-5 py-3 text-slate-500">{e.details ?? ""}</td>
              </tr>
            ))}
            {liste.length === 0 && (
              <tr>
                <td colSpan={5} className="px-5 py-10 text-center text-slate-400">
                  Aucune action
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      <p className="text-sm text-slate-400 mt-3">{liste.length} action(s)</p>
    </div>
  );
}
