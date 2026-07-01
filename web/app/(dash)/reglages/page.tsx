import { getCategories, getSites } from "@/lib/data";
import ReglagesManager from "@/components/ReglagesManager";

export const dynamic = "force-dynamic";

export default async function ReglagesPage() {
  const [categories, sites] = await Promise.all([getCategories(), getSites()]);
  return (
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold text-slate-900">Réglages</h1>
      <p className="text-slate-500 mt-1 mb-6">
        Catégories et sites du stock.
      </p>
      <ReglagesManager categories={categories} sites={sites} />
    </div>
  );
}
