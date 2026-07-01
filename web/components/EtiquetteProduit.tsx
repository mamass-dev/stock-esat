"use client";

export default function EtiquetteProduit({
  qr,
  nom,
  reference,
}: {
  qr: string;
  nom: string;
  reference: string;
}) {
  return (
    <div>
      {/* Étiquette (seule chose imprimée) */}
      <div className="etiquette inline-flex items-center gap-4 rounded-xl border-2 border-slate-800 bg-white p-4">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={qr} alt="QR" className="w-28 h-28" />
        <div className="min-w-0">
          <div className="text-xl font-bold leading-tight text-slate-900">
            {nom}
          </div>
          <div className="text-sm font-mono text-slate-500 mt-1">
            {reference}
          </div>
        </div>
      </div>

      <div className="no-print mt-4">
        <button
          onClick={() => window.print()}
          className="inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-[#2557D6] hover:bg-[#1e4bb8] text-white font-semibold transition"
        >
          🖨️ Imprimer l&apos;étiquette
        </button>
        <p className="text-xs text-slate-400 mt-2">
          Astuce : dans la fenêtre d&apos;impression, choisissez « Marges : aucune »
          pour une étiquette bien cadrée.
        </p>
      </div>
    </div>
  );
}
