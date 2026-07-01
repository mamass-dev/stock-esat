import { sbAdmin } from "@/lib/admin";
import OperateursManager, { Operateur } from "@/components/OperateursManager";

export const dynamic = "force-dynamic";

export default async function OperateursPage() {
  const { data } = await sbAdmin()
    .from("operateurs")
    .select("id,nom,role,actif")
    .order("nom");
  const operateurs = (data as Operateur[]) ?? [];

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold text-slate-900">Opérateurs</h1>
      <p className="text-slate-500 mt-1 mb-6">
        Comptes et codes PIN. Le PIN n&apos;est jamais affiché (stocké chiffré).
      </p>
      <OperateursManager operateurs={operateurs} />
    </div>
  );
}
