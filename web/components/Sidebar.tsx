"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

const items = [
  { href: "/", label: "Tableau de bord", icon: "📊" },
  { href: "/inventaire", label: "Inventaire", icon: "📦" },
  { href: "/a-commander", label: "À commander", icon: "🛒" },
  { href: "/mouvements", label: "Mouvements", icon: "🔄" },
  { href: "/journal", label: "Journal", icon: "📝" },
  { href: "/operateurs", label: "Opérateurs", icon: "👥" },
  { href: "/reglages", label: "Réglages", icon: "🗂️" },
];

export default function Sidebar() {
  const path = usePathname();
  const router = useRouter();

  async function logout() {
    await fetch("/api/logout", { method: "POST" });
    router.replace("/login");
    router.refresh();
  }
  return (
    <aside className="w-64 shrink-0 bg-white border-r border-slate-200 flex flex-col">
      <div className="p-5 border-b border-slate-100">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/logo.svg" alt="VYV3 Bourgogne" className="h-10 mb-2" />
        <div className="font-bold text-slate-900 leading-tight">Stock&apos;ESAT</div>
        <div className="text-xs text-slate-400">Pilotage responsable</div>
      </div>

      <nav className="p-3 flex flex-col gap-1">
        {items.map((it) => {
          const active = path === it.href;
          return (
            <Link
              key={it.href}
              href={it.href}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl text-[15px] font-medium transition ${
                active
                  ? "bg-[#2557D6] text-white shadow-sm shadow-blue-200"
                  : "text-slate-600 hover:bg-slate-100"
              }`}
            >
              <span className="text-lg">{it.icon}</span>
              {it.label}
            </Link>
          );
        })}
      </nav>

      <div className="mt-auto p-3 flex flex-col gap-2">
        <a
          href="/api/export"
          className="flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-semibold text-[15px] transition"
        >
          ⬇️ Export Excel
        </a>
        <button
          onClick={logout}
          className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-slate-500 hover:bg-slate-100 font-medium text-sm transition"
        >
          🔒 Déconnexion
        </button>
      </div>
    </aside>
  );
}
