"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Ref } from "@/lib/data";

function ListManager({
  titre,
  items,
  endpoint,
}: {
  titre: string;
  items: Ref[];
  endpoint: string;
}) {
  const router = useRouter();
  const [nom, setNom] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  async function call(method: string, body: Record<string, unknown>) {
    setErr(null);
    setBusy(true);
    const res = await fetch(endpoint, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    setBusy(false);
    if (!res.ok) {
      setErr((await res.json().catch(() => ({})))?.error ?? "Erreur");
      return;
    }
    router.refresh();
  }

  return (
    <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-6">
      <h2 className="font-bold text-slate-900 mb-4">{titre}</h2>

      <div className="flex gap-2 mb-4">
        <input
          value={nom}
          onChange={(e) => setNom(e.target.value)}
          placeholder="Nouveau…"
          onKeyDown={(e) => {
            if (e.key === "Enter" && nom.trim()) {
              call("POST", { nom });
              setNom("");
            }
          }}
          className="flex-1 px-4 py-2 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
        />
        <button
          onClick={() => {
            if (nom.trim()) {
              call("POST", { nom });
              setNom("");
            }
          }}
          disabled={busy || !nom.trim()}
          className="px-4 py-2 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-semibold disabled:opacity-50"
        >
          ＋
        </button>
      </div>

      {err && <p className="text-red-600 text-sm mb-2">⚠ {err}</p>}

      <ul className="divide-y divide-slate-100">
        {items.map((it) => (
          <li key={it.id} className="flex items-center justify-between py-2.5">
            <span className="text-slate-800">{it.nom}</span>
            <div className="flex gap-3 text-sm">
              <button
                onClick={() => {
                  const n = window.prompt("Renommer :", it.nom);
                  if (n && n.trim()) call("PATCH", { id: it.id, nom: n.trim() });
                }}
                className="text-[#2557D6] hover:underline"
              >
                Renommer
              </button>
              <button
                onClick={() => {
                  if (window.confirm(`Supprimer « ${it.nom} » ?`))
                    call("DELETE", { id: it.id });
                }}
                className="text-red-500 hover:underline"
              >
                Supprimer
              </button>
            </div>
          </li>
        ))}
        {items.length === 0 && (
          <li className="py-3 text-slate-400 text-sm">Aucun élément</li>
        )}
      </ul>
    </div>
  );
}

export default function ReglagesManager({
  categories,
  sites,
}: {
  categories: Ref[];
  sites: Ref[];
}) {
  return (
    <div className="grid md:grid-cols-2 gap-6">
      <ListManager
        titre="Catégories"
        items={categories}
        endpoint="/api/admin/categories"
      />
      <ListManager titre="Sites" items={sites} endpoint="/api/admin/sites" />
    </div>
  );
}
