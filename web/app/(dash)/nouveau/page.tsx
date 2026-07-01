import Link from "next/link";
import { getCategories, getSites, getProduits } from "@/lib/data";
import NouveauProduitForm from "@/components/NouveauProduitForm";

export const dynamic = "force-dynamic";

export default async function NouveauProduitPage() {
  const [categories, sites, produits] = await Promise.all([
    getCategories(),
    getSites(),
    getProduits(),
  ]);
  const existants = produits.map((p) => ({ nom: p.nom, ref: p.ref }));

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <Link
        href="/inventaire"
        className="text-sm text-slate-500 hover:text-slate-800"
      >
        ← Retour à l&apos;inventaire
      </Link>
      <h1 className="text-3xl font-bold text-slate-900 mt-4">
        Nouveau produit
      </h1>
      <p className="text-slate-500 mt-1 mb-6">
        La référence est générée automatiquement à partir du nom.
      </p>
      <NouveauProduitForm
        categories={categories}
        sites={sites}
        existants={existants}
      />
    </div>
  );
}
