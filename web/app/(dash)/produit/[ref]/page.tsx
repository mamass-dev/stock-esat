import QRCode from "qrcode";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getProduitByRef, statut } from "@/lib/data";
import EtiquetteProduit from "@/components/EtiquetteProduit";
import MouvementRapide from "@/components/MouvementRapide";

export const dynamic = "force-dynamic";

const BADGE: Record<string, { txt: string; cls: string }> = {
  ok: { txt: "🟢 OK", cls: "bg-emerald-50 text-emerald-700" },
  faible: { txt: "🟠 Faible", cls: "bg-amber-50 text-amber-700" },
  rupture: { txt: "🔴 Rupture", cls: "bg-red-50 text-red-700" },
};

export default async function FicheProduit({
  params,
}: {
  params: Promise<{ ref: string }>;
}) {
  const { ref } = await params;
  const p = await getProduitByRef(decodeURIComponent(ref));
  if (!p) notFound();

  const qr = await QRCode.toDataURL(`P:${p.ref}`, { margin: 1, width: 300 });
  const s = statut(p);
  const lieu = p.sites?.nom ?? null;

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <Link
        href="/inventaire"
        className="no-print text-sm text-slate-500 hover:text-slate-800"
      >
        ← Retour à l&apos;inventaire
      </Link>

      <div className="grid md:grid-cols-2 gap-6 mt-4">
       <div className="flex flex-col gap-6">
        {/* Infos produit */}
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-6">
          <div className="flex items-center gap-4">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            {p.photo_url ? (
              <img
                src={p.photo_url}
                alt=""
                className="w-24 h-24 rounded-xl object-cover"
              />
            ) : (
              <div className="w-24 h-24 rounded-xl bg-slate-100 flex items-center justify-center text-4xl">
                📦
              </div>
            )}
            <div>
              <h1 className="text-2xl font-bold text-slate-900">{p.nom}</h1>
              <div className="text-sm font-mono text-slate-400">{p.ref}</div>
              <span
                className={`inline-block mt-2 px-3 py-1 rounded-full text-xs font-semibold ${BADGE[s].cls}`}
              >
                {BADGE[s].txt}
              </span>
            </div>
          </div>

          <dl className="mt-6 grid grid-cols-2 gap-y-3 text-sm">
            <dt className="text-slate-400">Stock actuel</dt>
            <dd className="font-bold text-slate-800">
              {p.stock_courant} {p.unite ?? ""}
            </dd>
            <dt className="text-slate-400">Catégorie</dt>
            <dd className="text-slate-700">{p.categories?.nom ?? "—"}</dd>
            <dt className="text-slate-400">Site</dt>
            <dd className="text-slate-700">{p.sites?.nom ?? "—"}</dd>
            <dt className="text-slate-400">Seuil mini</dt>
            <dd className="text-slate-700">{p.seuil_mini}</dd>
            <dt className="text-slate-400">Seuil cible</dt>
            <dd className="text-slate-700">{p.seuil_cible}</dd>
          </dl>
        </div>

        {/* Mouvement de stock */}
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-6">
          <h2 className="font-bold text-slate-900 mb-4">Mouvement de stock</h2>
          <MouvementRapide
            produitId={p.id}
            stock={p.stock_courant}
            unite={p.unite}
          />
        </div>
       </div>

        {/* Étiquette */}
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-6">
          <h2 className="font-bold text-slate-900 mb-4">Étiquette QR</h2>
          <EtiquetteProduit
            qr={qr}
            nom={p.nom}
            reference={p.ref}
            lieu={lieu}
          />
        </div>
      </div>
    </div>
  );
}
