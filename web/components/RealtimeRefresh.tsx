"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { sb } from "@/lib/supabase";

// Écoute les changements de la base (mouvements, produits, alertes) et
// rafraîchit automatiquement la page. Affiche un indicateur "Temps réel".
export default function RealtimeRefresh() {
  const router = useRouter();
  const [flash, setFlash] = useState(false);

  useEffect(() => {
    const client = sb();
    let refresh: ReturnType<typeof setTimeout>;
    let clear: ReturnType<typeof setTimeout>;

    const bump = () => {
      setFlash(true);
      clearTimeout(clear);
      clear = setTimeout(() => setFlash(false), 1600);
      clearTimeout(refresh);
      refresh = setTimeout(() => router.refresh(), 500);
    };

    const ch = client
      .channel("dash-rt")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "mouvements" },
        bump
      )
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "produits" },
        bump
      )
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "alertes" },
        bump
      )
      .subscribe();

    return () => {
      client.removeChannel(ch);
      clearTimeout(refresh);
      clearTimeout(clear);
    };
  }, [router]);

  return (
    <div className="fixed bottom-4 right-4 z-40 flex items-center gap-2 px-3.5 py-2 rounded-full bg-white border border-slate-200 shadow-md text-xs">
      <span className="relative flex h-2.5 w-2.5">
        {!flash && (
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
        )}
        <span
          className={`relative inline-flex rounded-full h-2.5 w-2.5 ${
            flash ? "bg-[#2557D6]" : "bg-emerald-500"
          }`}
        ></span>
      </span>
      <span className="text-slate-600 font-semibold">
        {flash ? "Mis à jour" : "Temps réel"}
      </span>
    </div>
  );
}
