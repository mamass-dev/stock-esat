"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import type { StockLigne, Ref, Lieu } from "@/lib/data";

type FStatut = "tous" | "ok" | "faible" | "rupture";

function statut(s: StockLigne): Exclude<FStatut, "tous"> {
  if (s.stock_courant <= s.seuil_rupture) return "rupture";
  if (s.stock_courant <= s.seuil_mini) return "faible";
  return "ok";
}

const BADGE: Record<string, { txt: string; cls: string }> = {
  ok: { txt: "🟢 OK", cls: "bg-emerald-50 text-emerald-700" },
  faible: { txt: "🟠 Faible", cls: "bg-amber-50 text-amber-700" },
  rupture: { txt: "🔴 Rupture", cls: "bg-red-50 text-red-700" },
};

type EditForm = {
  nom: string;
  categorieId: string;
  unite: string;
  seuilMini: string;
  seuilCible: string;
};

export default function StocksTable({
  stocks,
  categories,
  sites,
}: {
  stocks: StockLigne[];
  categories: Ref[];
  sites: Lieu[];
}) {
  const [items, setItems] = useState(stocks);
  const [q, setQ] = useState("");
  const [statutF, setStatutF] = useState<FStatut>("tous");
  const [catF, setCatF] = useState("");
  const [lieuF, setLieuF] = useState("");

  const [edit, setEdit] = useState<StockLigne | null>(null);
  const [form, setForm] = useState<EditForm | null>(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [suppr, setSuppr] = useState<StockLigne | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const sitesSeuls = sites.filter((s) => s.type === "Site");
  const prestations = sites.filter((s) => s.type === "Prestation");

  const liste = useMemo(
    () =>
      items.filter((s) => {
        if (statutF !== "tous" && statut(s) !== statutF) return false;
        if (catF && s.categorie_id !== catF) return false;
        if (lieuF && s.site_id !== lieuF) return false;
        if (q && !s.nom.toLowerCase().includes(q.toLowerCase())) return false;
        return true;
      }),
    [items, q, statutF, catF, lieuF]
  );

  function flash(m: string) {
    setToast(m);
    setTimeout(() => setToast(null), 3500);
  }

  function ouvrir(s: StockLigne) {
    setEdit(s);
    setErr(null);
    setForm({
      nom: s.nom,
      categorieId: s.categorie_id ?? "",
      unite: s.unite ?? "",
      seuilMini: String(s.seuil_mini),
      seuilCible: String(s.seuil_cible),
    });
  }

  async function enregistrer() {
    if (!edit || !form) return;
    setBusy(true);
    setErr(null);
    const res = await fetch("/api/admin/stock", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        stockId: edit.id,
        produitId: edit.produit_id,
        ...form,
      }),
    });
    setBusy(false);
    if (!res.ok) {
      setErr((await res.json().catch(() => ({})))?.error ?? "Erreur");
      return;
    }
    const catNom = categories.find((c) => c.id === form.categorieId)?.nom ?? null;
    setItems((prev) =>
      prev.map((x) =>
        // le nom/catégorie change pour TOUTES les lignes du produit
        x.produit_id === edit.produit_id
          ? {
              ...x,
              nom: form.nom.trim(),
              unite: form.unite.trim() || null,
              categorie_id: form.categorieId || null,
              categorie_nom: catNom,
              ...(x.id === edit.id
                ? {
                    seuil_mini: Number(form.seuilMini) || 0,
                    seuil_cible: Number(form.seuilCible) || 0,
                  }
                : {}),
            }
          : x
      )
    );
    flash(`« ${form.nom.trim()} » modifié`);
    setEdit(null);
  }

  async function confirmerSuppr() {
    if (!suppr) return;
    setBusy(true);
    setErr(null);
    const res = await fetch("/api/admin/stock", {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ stockId: suppr.id }),
    });
    setBusy(false);
    if (!res.ok) {
      setErr((await res.json().catch(() => ({})))?.error ?? "Erreur");
      return;
    }
    setItems((prev) => prev.filter((x) => x.id !== suppr.id));
    flash(`« ${suppr.nom} » retiré de ${suppr.site_nom}`);
    setSuppr(null);
  }

  const chips: { k: FStatut; label: string }[] = [
    { k: "tous", label: "Tous" },
    { k: "ok", label: "🟢 OK" },
    { k: "faible", label: "🟠 Faibles" },
    { k: "rupture", label: "🔴 Ruptures" },
  ];
  const setF = (p: Partial<EditForm>) =>
    setForm((f) => (f ? { ...f, ...p } : f));

  return (
    <div>
      <div className="flex flex-wrap gap-3 items-center mb-5">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Rechercher un produit…"
          className="flex-1 min-w-[200px] px-4 py-2.5 rounded-xl border border-slate-200 bg-white outline-none focus:border-[#2557D6]"
        />
        <select
          value={catF}
          onChange={(e) => setCatF(e.target.value)}
          className="px-3 py-2.5 rounded-xl border border-slate-200 bg-white text-sm outline-none focus:border-[#2557D6]"
        >
          <option value="">Toutes catégories</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.nom}
            </option>
          ))}
        </select>
        <select
          value={lieuF}
          onChange={(e) => setLieuF(e.target.value)}
          className="px-3 py-2.5 rounded-xl border border-slate-200 bg-white text-sm outline-none focus:border-[#2557D6]"
        >
          <option value="">Tous les lieux</option>
          {sitesSeuls.length > 0 && (
            <optgroup label="Sites">
              {sitesSeuls.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.nom}
                </option>
              ))}
            </optgroup>
          )}
          {prestations.length > 0 && (
            <optgroup label="Prestations">
              {prestations.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.nom}
                </option>
              ))}
            </optgroup>
          )}
        </select>
        <div className="flex gap-2">
          {chips.map((c) => (
            <button
              key={c.k}
              onClick={() => setStatutF(c.k)}
              className={`px-4 py-2 rounded-xl text-sm font-medium transition ${
                statutF === c.k
                  ? "bg-[#2557D6] text-white"
                  : "bg-white border border-slate-200 text-slate-600 hover:bg-slate-50"
              }`}
            >
              {c.label}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-400 border-b border-slate-100">
              <th className="px-5 py-3 font-semibold">Produit</th>
              <th className="px-5 py-3 font-semibold">Lieu</th>
              <th className="px-5 py-3 font-semibold">Catégorie</th>
              <th className="px-5 py-3 font-semibold text-right">Stock</th>
              <th className="px-5 py-3 font-semibold text-right">Statut</th>
              <th className="px-5 py-3"></th>
            </tr>
          </thead>
          <tbody>
            {liste.map((s) => {
              const st = statut(s);
              return (
                <tr
                  key={s.id}
                  className="group border-b border-slate-50 hover:bg-slate-50/60"
                >
                  <td className="px-5 py-3">
                    <div className="flex items-center gap-3">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      {s.photo_url ? (
                        <img
                          src={s.photo_url}
                          alt=""
                          className="w-10 h-10 rounded-lg object-cover"
                        />
                      ) : (
                        <div className="w-10 h-10 rounded-lg bg-slate-100 flex items-center justify-center text-slate-400">
                          📦
                        </div>
                      )}
                      <div>
                        <Link
                          href={`/produit/${encodeURIComponent(s.ref)}`}
                          className="font-medium text-slate-800 hover:text-[#2557D6] hover:underline"
                        >
                          {s.nom}
                        </Link>
                        <div className="text-xs text-slate-400">{s.ref}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-3 text-slate-600 whitespace-nowrap">
                    {s.site_type === "Prestation" ? "🧾" : "📍"} {s.site_nom}
                  </td>
                  <td className="px-5 py-3 text-slate-600">
                    {s.categorie_nom ?? "—"}
                  </td>
                  <td className="px-5 py-3 text-right font-bold text-slate-800">
                    {s.stock_courant}
                    {s.unite ? (
                      <span className="text-xs font-normal text-slate-400">
                        {" "}
                        {s.unite}
                      </span>
                    ) : null}
                  </td>
                  <td className="px-5 py-3 text-right">
                    <span
                      className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${BADGE[st].cls}`}
                    >
                      {BADGE[st].txt}
                    </span>
                  </td>
                  <td className="px-3 py-3 text-right whitespace-nowrap">
                    <button
                      onClick={() => ouvrir(s)}
                      title="Modifier"
                      className="opacity-0 group-hover:opacity-100 transition text-slate-400 hover:text-[#2557D6] p-2 rounded-lg hover:bg-blue-50"
                    >
                      ✏️
                    </button>
                    <button
                      onClick={() => {
                        setSuppr(s);
                        setErr(null);
                      }}
                      title="Retirer de ce lieu"
                      className="opacity-0 group-hover:opacity-100 transition text-slate-400 hover:text-red-600 p-2 rounded-lg hover:bg-red-50"
                    >
                      🗑️
                    </button>
                  </td>
                </tr>
              );
            })}
            {liste.length === 0 && (
              <tr>
                <td colSpan={6} className="px-5 py-10 text-center text-slate-400">
                  Aucune ligne de stock
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      <p className="text-sm text-slate-400 mt-3">
        {liste.length} ligne(s) de stock
      </p>

      {/* Modale édition */}
      {edit && form && (
        <div
          className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4"
          onClick={() => !busy && setEdit(null)}
        >
          <div
            className="bg-white rounded-2xl p-6 w-full max-w-lg shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="text-lg font-bold text-slate-900">
              Modifier · {edit.site_nom}
            </h3>
            <p className="text-xs text-slate-400 mb-4">
              Le nom, la catégorie et l&apos;unité s&apos;appliquent au produit
              partout. Les seuils sont propres à ce lieu.
            </p>
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2">
                <label className="block text-sm font-medium text-slate-600 mb-1">
                  Nom
                </label>
                <input
                  value={form.nom}
                  onChange={(e) => setF({ nom: e.target.value })}
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-600 mb-1">
                  Catégorie
                </label>
                <select
                  value={form.categorieId}
                  onChange={(e) => setF({ categorieId: e.target.value })}
                  className="w-full px-3 py-2.5 rounded-xl border border-slate-200 bg-white outline-none focus:border-[#2557D6]"
                >
                  <option value="">—</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.nom}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-600 mb-1">
                  Unité
                </label>
                <input
                  value={form.unite}
                  onChange={(e) => setF({ unite: e.target.value })}
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-600 mb-1">
                  Seuil mini 🟠 (ce lieu)
                </label>
                <input
                  inputMode="numeric"
                  value={form.seuilMini}
                  onChange={(e) =>
                    setF({ seuilMini: e.target.value.replace(/\D/g, "") })
                  }
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-600 mb-1">
                  Seuil cible (ce lieu)
                </label>
                <input
                  inputMode="numeric"
                  value={form.seuilCible}
                  onChange={(e) =>
                    setF({ seuilCible: e.target.value.replace(/\D/g, "") })
                  }
                  className="w-full px-4 py-2.5 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
                />
              </div>
            </div>
            {err && <p className="text-red-600 text-sm mt-3">⚠ {err}</p>}
            <div className="flex gap-3 mt-5">
              <button
                onClick={() => setEdit(null)}
                disabled={busy}
                className="flex-1 py-2.5 rounded-xl border border-slate-200 font-medium text-slate-600 hover:bg-slate-50"
              >
                Annuler
              </button>
              <button
                onClick={enregistrer}
                disabled={busy || !form.nom.trim()}
                className="flex-1 py-2.5 rounded-xl bg-[#2557D6] text-white font-semibold hover:bg-[#1e4bb8] disabled:opacity-50"
              >
                {busy ? "Enregistrement…" : "Enregistrer"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modale suppression */}
      {suppr && (
        <div
          className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4"
          onClick={() => !busy && setSuppr(null)}
        >
          <div
            className="bg-white rounded-2xl p-6 w-full max-w-md shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="text-lg font-bold text-slate-900">Retirer de ce lieu ?</h3>
            <p className="text-slate-600 mt-1">
              <span className="font-semibold">{suppr.nom}</span> sera retiré de{" "}
              <span className="font-semibold">{suppr.site_nom}</span>. Le produit
              reste disponible sur les autres lieux.
            </p>
            {err && <p className="text-red-600 text-sm mt-3">⚠ {err}</p>}
            <div className="flex gap-3 mt-5">
              <button
                onClick={() => setSuppr(null)}
                disabled={busy}
                className="flex-1 py-2.5 rounded-xl border border-slate-200 font-medium text-slate-600 hover:bg-slate-50"
              >
                Annuler
              </button>
              <button
                onClick={confirmerSuppr}
                disabled={busy}
                className="flex-1 py-2.5 rounded-xl bg-red-600 text-white font-semibold hover:bg-red-700 disabled:opacity-50"
              >
                {busy ? "…" : "Retirer"}
              </button>
            </div>
          </div>
        </div>
      )}

      {toast && (
        <div className="fixed bottom-6 right-6 bg-slate-900 text-white px-5 py-3 rounded-xl shadow-lg z-50">
          ✅ {toast}
        </div>
      )}
    </div>
  );
}
