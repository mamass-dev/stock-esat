import { getProduits, aCommander } from "@/lib/data";

export const dynamic = "force-dynamic";

export default async function ACommanderPage() {
  const produits = await getProduits();
  const liste = aCommander(produits);

  return (
    <div className="p-8 max-w-5xl mx-auto">
      <h1 className="text-3xl font-bold text-slate-900">À commander</h1>
      <p className="text-slate-500 mt-1 mb-6">
        Produits au seuil ou en rupture, avec la quantité suggérée.
      </p>

      {liste.length === 0 ? (
        <div className="bg-emerald-50 text-emerald-700 rounded-2xl p-8 text-center font-medium">
          ✅ Rien à commander — tous les stocks sont au-dessus du seuil.
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-slate-400 border-b border-slate-100">
                <th className="px-5 py-3 font-semibold">Produit</th>
                <th className="px-5 py-3 font-semibold">Site</th>
                <th className="px-5 py-3 font-semibold text-right">Stock</th>
                <th className="px-5 py-3 font-semibold text-right">Seuil cible</th>
                <th className="px-5 py-3 font-semibold text-right">À commander</th>
              </tr>
            </thead>
            <tbody>
              {liste.map((p) => (
                <tr key={p.ref} className="border-b border-slate-50">
                  <td className="px-5 py-3">
                    <div className="font-medium text-slate-800">{p.nom}</div>
                    <div className="text-xs text-slate-400">{p.ref}</div>
                  </td>
                  <td className="px-5 py-3 text-slate-600">
                    {p.sites?.nom ?? "—"}
                  </td>
                  <td className="px-5 py-3 text-right font-semibold text-red-600">
                    {p.stock_courant}
                  </td>
                  <td className="px-5 py-3 text-right text-slate-600">
                    {p.seuil_cible}
                  </td>
                  <td className="px-5 py-3 text-right">
                    <span className="inline-block px-3 py-1 rounded-full bg-[#E7EEFB] text-[#2557D6] font-bold">
                      +{p.qte}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
