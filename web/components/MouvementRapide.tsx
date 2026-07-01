"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { sb } from "@/lib/supabase";

export default function MouvementRapide({
  produitId,
  stock,
  unite,
}: {
  produitId: string;
  stock: number;
  unite: string | null;
}) {
  const router = useRouter();
  const [type, setType] = useState<"Entrée" | "Sortie">("Entrée");
  const [qte, setQte] = useState(1);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(null);

  const maxSortie = type === "Sortie" ? stock : 9999;

  async function valider() {
    if (qte < 1) return;
    setBusy(true);
    setErr(null);
    const { error } = await sb().from("mouvements").insert({
      type,
      produit_id: produitId,
      quantite: qte,
      client_key: crypto.randomUUID(),
      source: "Web",
    });
    setBusy(false);
    if (error) {
      setErr(error.message);
      return;
    }
    setMsg(`${type} de ${qte} enregistrée`);
    setTimeout(() => setMsg(null), 3500);
    setQte(1);
    router.refresh();
  }

  return (
    <div>
      <div className="flex gap-2 mb-4">
        {(["Entrée", "Sortie"] as const).map((t) => (
          <button
            key={t}
            onClick={() => {
              setType(t);
              setQte(1);
            }}
            className={`flex-1 py-2 rounded-xl font-semibold text-sm transition ${
              type === t
                ? t === "Entrée"
                  ? "bg-emerald-500 text-white"
                  : "bg-[#2557D6] text-white"
                : "bg-slate-100 text-slate-600"
            }`}
          >
            {t === "Entrée" ? "＋ Entrée" : "− Sortie"}
          </button>
        ))}
      </div>

      <div className="flex items-center gap-3">
        <button
          onClick={() => setQte((q) => Math.max(1, q - 1))}
          className="w-11 h-11 rounded-xl bg-slate-100 text-xl font-bold text-slate-600"
        >
          −
        </button>
        <input
          value={qte}
          inputMode="numeric"
          onChange={(e) => {
            const n = parseInt(e.target.value.replace(/\D/g, "")) || 0;
            setQte(Math.min(Math.max(1, n), maxSortie));
          }}
          className="w-20 text-center text-2xl font-bold py-2 rounded-xl border border-slate-200"
        />
        <button
          onClick={() => setQte((q) => Math.min(maxSortie, q + 1))}
          className="w-11 h-11 rounded-xl bg-slate-100 text-xl font-bold text-slate-600"
        >
          ＋
        </button>
        <span className="text-slate-400 text-sm">{unite ?? ""}</span>
      </div>

      <p className="text-sm text-slate-500 mt-3">
        Nouveau stock :{" "}
        <span className="font-bold text-slate-800">
          {type === "Entrée" ? stock + qte : stock - qte}
        </span>
      </p>

      {err && <p className="text-red-600 text-sm mt-2">⚠ {err}</p>}
      {msg && <p className="text-emerald-600 text-sm mt-2">✅ {msg}</p>}

      <button
        onClick={valider}
        disabled={busy || (type === "Sortie" && stock <= 0)}
        className="mt-4 w-full py-3 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-semibold disabled:opacity-50"
      >
        {busy ? "Enregistrement…" : "Valider le mouvement"}
      </button>
    </div>
  );
}
