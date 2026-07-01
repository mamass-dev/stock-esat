import Link from "next/link";
import { getProduits, getCategories, getSites } from "@/lib/data";
import InventaireTable from "@/components/InventaireTable";

export const dynamic = "force-dynamic";

export default async function InventairePage() {
  const [produits, categories, sites] = await Promise.all([
    getProduits(),
    getCategories(),
    getSites(),
  ]);
  return (
    <div className="p-8 max-w-6xl mx-auto">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Inventaire</h1>
          <p className="text-slate-500 mt-1 mb-6">
            Toutes les références et leur niveau de stock.
          </p>
        </div>
        <Link
          href="/nouveau"
          className="px-5 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-semibold whitespace-nowrap"
        >
          ＋ Nouveau produit
        </Link>
      </div>
      <InventaireTable
        produits={produits}
        categories={categories}
        sites={sites}
      />
    </div>
  );
}
