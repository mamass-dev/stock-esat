import { getProduits } from "@/lib/data";
import EtiquettesPlanche, {
  ProduitEtiquette,
} from "@/components/EtiquettesPlanche";

export const dynamic = "force-dynamic";

export default async function EtiquettesPage() {
  const produits = await getProduits();
  const liste: ProduitEtiquette[] = produits.map((p) => ({
    id: p.id,
    ref: p.ref,
    nom: p.nom,
    site: p.sites?.nom ?? null,
  }));

  return (
    <div className="p-8 max-w-5xl mx-auto">
      <h1 className="text-3xl font-bold text-slate-900">Étiquettes</h1>
      <p className="text-slate-500 mt-1 mb-6">
        Sélectionnez des produits et imprimez une planche d&apos;étiquettes QR
        (nom + référence) sur une page A4.
      </p>
      <EtiquettesPlanche produits={liste} />
    </div>
  );
}
