"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import type { Ref } from "@/lib/data";
import { sb } from "@/lib/supabase";
import { genererRef } from "@/lib/genRef";

// Normalise pour comparer sans accents ni casse.
function norm(s: string): string {
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .trim();
}

export default function NouveauProduitForm({
  categories,
  sites,
  existants,
}: {
  categories: Ref[];
  sites: Ref[];
  existants: { nom: string; ref: string }[];
}) {
  const router = useRouter();
  const [nom, setNom] = useState("");
  const [categorieId, setCategorieId] = useState("");
  const [siteId, setSiteId] = useState("");
  const [unite, setUnite] = useState("");
  const [stock, setStock] = useState("0");
  const [seuilMini, setSeuilMini] = useState("0");
  const [seuilCible, setSeuilCible] = useState("0");
  const [photoUrl, setPhotoUrl] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  async function onPhoto(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    setErr(null);
    try {
      const path = `${crypto.randomUUID()}.jpg`;
      const { error } = await sb()
        .storage.from("produits-photos")
        .upload(path, file, { contentType: file.type, upsert: false });
      if (error) throw error;
      const { data } = sb().storage.from("produits-photos").getPublicUrl(path);
      setPhotoUrl(data.publicUrl);
    } catch (e) {
      setErr("Upload photo : " + (e as Error).message);
    } finally {
      setUploading(false);
    }
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    const res = await fetch("/api/admin/produit", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        nom,
        categorieId,
        siteId,
        unite,
        stockInitial: Number(stock) || 0,
        seuilMini: Number(seuilMini) || 0,
        seuilCible: Number(seuilCible) || 0,
        photoUrl,
      }),
    });
    const data = await res.json().catch(() => ({}));
    setBusy(false);
    if (!res.ok) {
      setErr(data.error ?? "Erreur");
      return;
    }
    router.push("/inventaire");
    router.refresh();
  }

  const refApercu = nom.trim() ? genererRef(nom) : "";

  // Suggestions de produits existants ressemblants
  const nq = norm(nom);
  const suggestions = useMemo(() => {
    if (nq.length < 2) return [];
    return existants
      .filter((p) => norm(p.nom).includes(nq))
      .slice(0, 6);
  }, [existants, nq]);
  const exact =
    nq.length > 0 ? existants.find((p) => norm(p.nom) === nq) : undefined;

  return (
    <form
      onSubmit={submit}
      className="bg-white rounded-2xl border border-slate-100 shadow-sm p-6 max-w-2xl"
    >
      <div className="grid md:grid-cols-2 gap-4">
        <div className="md:col-span-2">
          <label className="block text-sm font-medium text-slate-600 mb-1">
            Nom du produit *
          </label>
          <input
            value={nom}
            onChange={(e) => setNom(e.target.value)}
            required
            className="w-full px-4 py-2.5 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
          />
          {refApercu && (
            <p className="text-xs text-slate-400 mt-1">
              Référence auto : <span className="font-mono">{refApercu}</span>
            </p>
          )}

          {exact && (
            <Link
              href={`/produit/${encodeURIComponent(exact.ref)}`}
              className="mt-2 flex items-center justify-between gap-3 text-sm font-medium text-red-700 bg-red-50 hover:bg-red-100 rounded-lg px-3 py-2 transition"
            >
              <span>⚠ Ce produit existe déjà — cliquez pour l&apos;ouvrir</span>
              <span className="text-xs font-mono text-red-400">{exact.ref}</span>
            </Link>
          )}

          {!exact && suggestions.length > 0 && (
            <div className="mt-2 rounded-xl border border-amber-200 bg-amber-50 px-3 py-2">
              <p className="text-xs font-semibold text-amber-700 mb-1">
                Produits existants qui ressemblent (cliquez pour ouvrir) :
              </p>
              <ul className="text-sm space-y-0.5">
                {suggestions.map((p) => (
                  <li key={p.ref}>
                    <Link
                      href={`/produit/${encodeURIComponent(p.ref)}`}
                      className="flex justify-between gap-3 rounded-md px-2 py-1 -mx-2 hover:bg-amber-100 transition text-slate-700"
                    >
                      <span>{p.nom}</span>
                      <span className="text-xs text-slate-400 font-mono">
                        {p.ref}
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-slate-600 mb-1">
            Catégorie
          </label>
          <select
            value={categorieId}
            onChange={(e) => setCategorieId(e.target.value)}
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
            value={siteId}
            onChange={(e) => setSiteId(e.target.value)}
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

        <Field label="Unité (bidon, sac…)" value={unite} onChange={setUnite} />
        <Field
          label="Stock actuel (quantité en réserve)"
          value={stock}
          onChange={setStock}
          num
        />
        <Field label="Seuil mini 🟠" value={seuilMini} onChange={setSeuilMini} num />
        <Field label="Seuil cible" value={seuilCible} onChange={setSeuilCible} num />

        <div className="md:col-span-2">
          <label className="block text-sm font-medium text-slate-600 mb-1">
            Photo (optionnel)
          </label>
          <div className="flex items-center gap-4">
            {photoUrl && (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={photoUrl} alt="" className="w-16 h-16 rounded-lg object-cover" />
            )}
            <input
              type="file"
              accept="image/*"
              onChange={onPhoto}
              className="text-sm"
            />
            {uploading && <span className="text-sm text-slate-400">Envoi…</span>}
          </div>
        </div>
      </div>

      {err && <p className="text-red-600 text-sm mt-4">⚠ {err}</p>}

      <button
        type="submit"
        disabled={busy || uploading || !nom.trim()}
        className="mt-6 px-6 py-3 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-semibold disabled:opacity-50"
      >
        {busy ? "Création…" : "Créer le produit"}
      </button>
    </form>
  );
}

function Field({
  label,
  value,
  onChange,
  num,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  num?: boolean;
}) {
  return (
    <div>
      <label className="block text-sm font-medium text-slate-600 mb-1">
        {label}
      </label>
      <input
        value={value}
        inputMode={num ? "numeric" : "text"}
        onChange={(e) =>
          onChange(num ? e.target.value.replace(/\D/g, "") : e.target.value)
        }
        className="w-full px-4 py-2.5 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
      />
    </div>
  );
}
