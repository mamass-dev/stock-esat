"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export type Operateur = {
  id: string;
  nom: string;
  role: string;
  actif: boolean;
};

const ROLES = [
  { v: "operateur", l: "Opérateur" },
  { v: "responsable", l: "Responsable" },
  { v: "admin", l: "Admin" },
];

export default function OperateursManager({
  operateurs,
}: {
  operateurs: Operateur[];
}) {
  const router = useRouter();
  const [nom, setNom] = useState("");
  const [pin, setPin] = useState("");
  const [role, setRole] = useState("operateur");
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(null);

  function flash(m: string) {
    setMsg(m);
    setTimeout(() => setMsg(null), 3500);
  }

  async function creer(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    if (!/^\d{4}$/.test(pin)) {
      setErr("Le PIN doit faire 4 chiffres.");
      return;
    }
    setBusy(true);
    const res = await fetch("/api/admin/operateurs", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ nom, pin, role }),
    });
    setBusy(false);
    if (!res.ok) {
      setErr((await res.json().catch(() => ({})))?.error ?? "Erreur");
      return;
    }
    setNom("");
    setPin("");
    setRole("operateur");
    flash("Opérateur créé");
    router.refresh();
  }

  async function patch(body: Record<string, unknown>, ok: string) {
    const res = await fetch("/api/admin/operateurs", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      setErr((await res.json().catch(() => ({})))?.error ?? "Erreur");
      return;
    }
    flash(ok);
    router.refresh();
  }

  function resetPin(o: Operateur) {
    const p = window.prompt(`Nouveau PIN (4 chiffres) pour ${o.nom} :`);
    if (p == null) return;
    if (!/^\d{4}$/.test(p)) {
      setErr("Le PIN doit faire 4 chiffres.");
      return;
    }
    patch({ id: o.id, pin: p }, "PIN mis à jour");
  }

  return (
    <div>
      {/* Création */}
      <form
        onSubmit={creer}
        className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5 flex flex-wrap items-end gap-3 mb-6"
      >
        <div className="flex-1 min-w-[160px]">
          <label className="block text-sm font-medium text-slate-600 mb-1">
            Nom
          </label>
          <input
            value={nom}
            onChange={(e) => setNom(e.target.value)}
            required
            className="w-full px-4 py-2.5 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
          />
        </div>
        <div className="w-28">
          <label className="block text-sm font-medium text-slate-600 mb-1">
            PIN
          </label>
          <input
            value={pin}
            inputMode="numeric"
            maxLength={4}
            onChange={(e) => setPin(e.target.value.replace(/\D/g, ""))}
            placeholder="4 chiffres"
            className="w-full px-4 py-2.5 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6] tracking-widest"
          />
        </div>
        <div className="w-40">
          <label className="block text-sm font-medium text-slate-600 mb-1">
            Rôle
          </label>
          <select
            value={role}
            onChange={(e) => setRole(e.target.value)}
            className="w-full px-3 py-2.5 rounded-xl border border-slate-200 bg-white outline-none focus:border-[#2557D6]"
          >
            {ROLES.map((r) => (
              <option key={r.v} value={r.v}>
                {r.l}
              </option>
            ))}
          </select>
        </div>
        <button
          type="submit"
          disabled={busy || !nom.trim()}
          className="px-5 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-semibold disabled:opacity-50"
        >
          ＋ Ajouter
        </button>
      </form>

      {err && <p className="text-red-600 text-sm mb-3">⚠ {err}</p>}
      {msg && <p className="text-emerald-600 text-sm mb-3">✅ {msg}</p>}

      {/* Liste */}
      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-400 border-b border-slate-100">
              <th className="px-5 py-3 font-semibold">Nom</th>
              <th className="px-5 py-3 font-semibold">Rôle</th>
              <th className="px-5 py-3 font-semibold">Actif</th>
              <th className="px-5 py-3 font-semibold text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {operateurs.map((o) => (
              <tr key={o.id} className="border-b border-slate-50">
                <td className="px-5 py-3 font-medium text-slate-800">{o.nom}</td>
                <td className="px-5 py-3">
                  <select
                    value={o.role}
                    onChange={(e) =>
                      patch({ id: o.id, role: e.target.value }, "Rôle mis à jour")
                    }
                    className="px-3 py-1.5 rounded-lg border border-slate-200 bg-white"
                  >
                    {ROLES.map((r) => (
                      <option key={r.v} value={r.v}>
                        {r.l}
                      </option>
                    ))}
                  </select>
                </td>
                <td className="px-5 py-3">
                  <button
                    onClick={() =>
                      patch(
                        { id: o.id, actif: !o.actif },
                        o.actif ? "Désactivé" : "Activé"
                      )
                    }
                    className={`px-3 py-1 rounded-full text-xs font-semibold ${
                      o.actif
                        ? "bg-emerald-50 text-emerald-700"
                        : "bg-slate-100 text-slate-500"
                    }`}
                  >
                    {o.actif ? "Actif" : "Inactif"}
                  </button>
                </td>
                <td className="px-5 py-3 text-right">
                  <button
                    onClick={() => resetPin(o)}
                    className="text-[#2557D6] hover:underline font-medium"
                  >
                    Changer le PIN
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
