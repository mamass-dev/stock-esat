import { getCategories, getSites } from "@/lib/data";
import ReglagesManager from "@/components/ReglagesManager";

export const dynamic = "force-dynamic";

export default async function ReglagesPage() {
  const [categories, lieux] = await Promise.all([getCategories(), getSites()]);
  const sites = lieux.filter((l) => l.type === "Site");
  const prestations = lieux.filter((l) => l.type === "Prestation");
  return (
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold text-slate-900">Réglages</h1>
      <p className="text-slate-500 mt-1 mb-6">
        Catégories, sites et prestations du stock.
      </p>
      <ReglagesManager
        categories={categories}
        sites={sites}
        prestations={prestations}
      />
    </div>
  );
}
