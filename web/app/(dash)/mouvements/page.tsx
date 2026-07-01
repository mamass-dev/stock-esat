import { sbAdmin } from "@/lib/admin";
import type { Mouvement } from "@/lib/data";
import MouvementsTable from "@/components/MouvementsTable";

export const dynamic = "force-dynamic";

export default async function MouvementsPage() {
  // Lecture privilégiée (serveur, session vérifiée) pour résoudre l'opérateur.
  const { data } = await sbAdmin()
    .from("mouvements")
    .select(
      "type,quantite,stock_avant,stock_apres,cree_le,source,produits(nom),operateurs(nom)"
    )
    .order("cree_le", { ascending: false })
    .limit(500);
  const mouvements = (data as unknown as Mouvement[]) ?? [];

  return (
    <div className="p-8 max-w-5xl mx-auto">
      <h1 className="text-3xl font-bold text-slate-900">Mouvements</h1>
      <p className="text-slate-500 mt-1 mb-6">
        Historique des entrées et sorties, avec l&apos;auteur.
      </p>
      <MouvementsTable mouvements={mouvements} />
    </div>
  );
}
