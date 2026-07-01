"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import type { Produit, Ref } from "@/lib/data";

type Filtre = "tous" | "ok" | "faible" | "rupture";

function statut(p: Produit): Exclude<Filtre, "tous"> {
  if (p.stock_courant <= p.seuil_rupture) return "rupture";
  if (p.stock_courant <= p.seuil_mini) return "faible";
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
  siteId: string;
  unite: string;
  seuilMini: string;
  seuilCible: string;
};

async function errMsg(res: Response) {
  return (await res.json().catch(() => ({})))?.error ?? "Erreur";
}

export default function InventaireTable({
  produits,
  categories,
  sites,
}: {
  produits: Produit[];
  categories: Ref[];
  sites: Ref[];
}) {
  const [items, setItems] = useState(produits);
  const [q, setQ] = useState("");
  const [filtre, setFiltre] = useState<Filtre>("tous");

  const [cible, setCible] = useState<Produit | null>(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const [edit, setEdit] = useState<Produit | null>(null);
  const [form, setForm] = useState<EditForm | null>(null);
  const [editBusy, setEditBusy] = useState(false);
  const [editErr, setEditErr] = useState<string | null>(null);

  const [toast, setToast] = useState<string | null>(null);

  const liste = useMemo(() => {
    return items.filter((p) => {
      if (filtre !== "tous" && statut(p) !== filtre) return false;
      if (q && !p.nom.toLowerCase().includes(q.toLowerCase())) return false;
      return true;
    });
  }, [items, q, filtre]);

  function flash(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 4000);
  }

  async function confirmerSuppr() {
    if (!cible) return;
    setBusy(true);
    setErr(null);
    const res = await fetch("/api/admin/produit", {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: cible.id }),
    });
    setBusy(false);
    if (!res.ok) {
      setErr(await errMsg(res));
      return;
    }
    const data = await res.json().catch(() => ({}));
    setItems((prev) => prev.filter((p) => p.id !== cible.id));
    flash(
      data.resultat === "archivé"
        ? `« ${cible.nom} » archivé (historique conservé)`
        : `« ${cible.nom} » supprimé`
    );
    setCible(null);
  }

  function ouvrirEdit(p: Produit) {
    setEdit(p);
    setEditErr(null);
    setForm({
      nom: p.nom,
      categorieId: p.categorie_id ?? "",
      siteId: p.site_id ?? "",
      unite: p.unite ?? "",
      seuilMini: String(p.seuil_mini),
      seuilCible: String(p.seuil_cible),
    });
  }

  async function confirmerEdit() {
    if (!edit || !form) return;
    setEditBusy(true);
    setEditErr(null);
    const res = await fetch("/api/admin/produit", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: edit.id, ...form }),
    });
    setEditBusy(false);
    if (!res.ok) {
      setEditErr(await errMsg(res));
      return;
    }
    const catNom = categories.find((c) => c.id === form.categorieId)?.nom ?? null;
    const siteNom = sites.find((s) => s.id === form.siteId)?.nom ?? null;
    setItems((prev) =>
      prev.map((p) =>
        p.id === edit.id
          ? {
              ...p,
              nom: form.nom.trim(),
              unite: form.unite.trim() || null,
              seuil_mini: Number(form.seuilMini) || 0,
              seuil_cible: Number(form.seuilCible) || 0,
              categorie_id: form.categorieId || null,
              site_id: form.siteId || null,
              categories: catNom ? { nom: catNom } : null,
              sites: siteNom ? { nom: siteNom } : null,
            }
          : p
      )
    );
    flash(`« ${form.nom.trim()} » modifié`);
    setEdit(null);
  }

  const chips: { k: Filtre; label: string }[] = [
    { k: "tous", label: "Tous" },
    { k: "ok", label: "🟢 OK" },
    { k: "faible", label: "🟠 Faibles" },
    { k: "rupture", label: "🔴 Ruptures" },
  ];

  const setF = (patch: Partial<EditForm>) =>
    setForm((f) => (f ? { ...f, ...patch } : f));

  return (
    <div>
      <div className="flex flex-wrap gap-3 items-center mb-5">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Rechercher un produit…"
          className="flex-1 min-w-[220px] px-4 py-2.5 rounded-xl border border-slate-200 bg-white outline-none focus:border-[#2557D6]"
        />
        <div className="flex gap-2">
          {chips.map((c) => (
            <button
              key={c.k}
              onClick={() => setFiltre(c.k)}
              className={`px-4 py-2 rounded-xl text-sm font-medium transition ${
                filtre === c.k
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
              <th className="px-5 py-3 font-semibold">Catégorie</th>
              <th className="px-5 py-3 font-semibold">Site</th>
              <th className="px-5 py-3 font-semibold text-right">Stock</th>
              <th className="px-5 py-3 font-semibold text-right">Statut</th>
              <th className="px-5 py-3"></th>
            </tr>
          </thead>
          <tbody>
            {liste.map((p) => {
              const s = statut(p);
              return (
                <tr
                  key={p.id}
                  className="group border-b border-slate-50 hover:bg-slate-50/60"
                >
                  <td className="px-5 py-3">
                    <div className="flex items-center gap-3">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      {p.photo_url ? (
                        <img
                          src={p.photo_url}
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
                          href={`/produit/${encodeURIComponent(p.ref)}`}
                          className="font-medium text-slate-800 hover:text-[#2557D6] hover:underline"
                        >
                          {p.nom}
                        </Link>
                        <div className="text-xs text-slate-400">{p.ref}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-3 text-slate-600">
                    {p.categories?.nom ?? "—"}
                  </td>
                  <td className="px-5 py-3 text-slate-600">
                    {p.sites?.nom ?? "—"}
                  </td>
                  <td className="px-5 py-3 text-right font-bold text-slate-800">
                    {p.stock_courant}
                    {p.unite ? (
                      <span className="text-xs font-normal text-slate-400">
                        {" "}
                        {p.unite}
                      </span>
                    ) : null}
                  </td>
                  <td className="px-5 py-3 text-right">
                    <span
                      className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${BADGE[s].cls}`}
                    >
                      {BADGE[s].txt}
                    </span>
                  </td>
                  <td className="px-3 py-3 text-right whitespace-nowrap">
                    <Link
                      href={`/produit/${encodeURIComponent(p.ref)}`}
                      title="Fiche & étiquette QR"
                      className="opacity-0 group-hover:opacity-100 transition text-slate-400 hover:text-[#2557D6] p-2 rounded-lg hover:bg-blue-50 inline-block"
                    >
                      🏷️
                    </Link>
                    <button
                      onClick={() => ouvrirEdit(p)}
                      title="Modifier"
                      className="opacity-0 group-hover:opacity-100 transition text-slate-400 hover:text-[#2557D6] p-2 rounded-lg hover:bg-blue-50"
                    >
                      ✏️
                    </button>
                    <button
                      onClick={() => {
                        setCible(p);
                        setErr(null);
                      }}
                      title="Supprimer"
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
                  Aucun produit
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      <p className="text-sm text-slate-400 mt-3">{liste.length} produit(s)</p>

      {/* ── Modale suppression ── */}
      {cible && (
        <div
          className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4"
          onClick={() => !busy && setCible(null)}
        >
          <div
            className="bg-white rounded-2xl p-6 w-full max-w-md shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="text-lg font-bold text-slate-900">
              Supprimer ce produit ?
            </h3>
            <p className="text-slate-600 mt-1">
              <span className="font-semibold">{cible.nom}</span>. S&apos;il a un
              historique, il sera archivé (historique conservé).
            </p>
            {err && <p className="text-red-600 text-sm mt-3">⚠ {err}</p>}
            <div className="flex gap-3 mt-5">
              <button
                onClick={() => setCible(null)}
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
                {busy ? "Suppression…" : "Supprimer"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Modale édition ── */}
      {edit && form && (
        <div
          className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4"
          onClick={() => !editBusy && setEdit(null)}
        >
          <div
            className="bg-white rounded-2xl p-6 w-full max-w-lg shadow-xl max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="text-lg font-bold text-slate-900 mb-4">
              Modifier le produit
            </h3>
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
                  Site
                </label>
                <select
                  value={form.siteId}
                  onChange={(e) => setF({ siteId: e.target.value })}
                  className="w-full px-3 py-2.5 rounded-xl border border-slate-200 bg-white outline-none focus:border-[#2557D6]"
                >
                  <option value="">—</option>
                  {sites.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.nom}
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
              <div />
              <div>
                <label className="block text-sm font-medium text-slate-600 mb-1">
                  Seuil mini 🟠
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
                  Seuil cible
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

            {editErr && <p className="text-red-600 text-sm mt-3">⚠ {editErr}</p>}

            <div className="flex gap-3 mt-5">
              <button
                onClick={() => setEdit(null)}
                disabled={editBusy}
                className="flex-1 py-2.5 rounded-xl border border-slate-200 font-medium text-slate-600 hover:bg-slate-50"
              >
                Annuler
              </button>
              <button
                onClick={confirmerEdit}
                disabled={editBusy || !form.nom.trim()}
                className="flex-1 py-2.5 rounded-xl bg-[#2557D6] text-white font-semibold hover:bg-[#1e4bb8] disabled:opacity-50"
              >
                {editBusy ? "Enregistrement…" : "Enregistrer"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Toast ── */}
      {toast && (
        <div className="fixed bottom-6 right-6 bg-slate-900 text-white px-5 py-3 rounded-xl shadow-lg z-50">
          ✅ {toast}
        </div>
      )}
    </div>
  );
}
