"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    const res = await fetch("/api/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    if (res.ok) {
      router.replace("/");
      router.refresh();
    } else {
      setErr("Identifiants incorrects.");
      setBusy(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-slate-50 to-slate-100 p-4">
      <div className="w-full max-w-md bg-white rounded-3xl shadow-xl p-8">
        <div className="mb-6">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo.svg" alt="VYV3 Bourgogne" className="h-16" />
          <div className="mt-3 font-bold text-lg text-slate-900 leading-tight">
            Stock&apos;ESAT
          </div>
          <div className="text-sm text-slate-400">Espace responsable</div>
        </div>

        <h1 className="text-2xl font-bold text-slate-900">Connexion</h1>
        <p className="text-slate-500 mt-1 mb-6 text-sm">
          Accès réservé au pilotage du stock.
        </p>

        <form onSubmit={submit} className="flex flex-col gap-4">
          <div>
            <label className="block text-sm font-medium text-slate-600 mb-1">
              Adresse e-mail
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoFocus
              className="w-full px-4 py-3 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
              placeholder="vous@exemple.fr"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-600 mb-1">
              Mot de passe
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full px-4 py-3 rounded-xl border border-slate-200 outline-none focus:border-[#2557D6]"
              placeholder="••••••••"
            />
          </div>

          {err && <p className="text-red-600 text-sm">⚠ {err}</p>}

          <button
            type="submit"
            disabled={busy}
            className="mt-2 py-3 rounded-xl bg-[#2557D6] hover:bg-[#1e4bb8] text-white font-semibold transition disabled:opacity-50"
          >
            {busy ? "Connexion…" : "Se connecter"}
          </button>
        </form>
      </div>
    </div>
  );
}
