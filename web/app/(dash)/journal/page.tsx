import { sbAdmin } from "@/lib/admin";
import JournalTable, { EntreeJournal } from "@/components/JournalTable";

export const dynamic = "force-dynamic";

export default async function JournalPage() {
  const { data } = await sbAdmin()
    .from("journal_produits")
    .select("action,produit_ref,produit_nom,details,acteur,cree_le")
    .order("cree_le", { ascending: false })
    .limit(500);
  const entrees = (data as EntreeJournal[]) ?? [];

  return (
    <div className="p-8 max-w-5xl mx-auto">
      <h1 className="text-3xl font-bold text-slate-900">Journal</h1>
      <p className="text-slate-500 mt-1 mb-6">
        Ajouts, modifications et suppressions de produits — qui, quoi, quand.
      </p>
      <JournalTable entrees={entrees} />
    </div>
  );
}
