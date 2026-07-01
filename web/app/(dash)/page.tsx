import {
  getStocks,
  getMouvements,
  agregerStocks,
  agregerMouvements,
} from "@/lib/data";
import ConsoChart from "@/components/ConsoChart";

export const dynamic = "force-dynamic";

function Stat({
  n,
  label,
  color,
  bg,
}: {
  n: number;
  label: string;
  color: string;
  bg: string;
}) {
  return (
    <div className="rounded-2xl p-5" style={{ background: bg }}>
      <div className="text-3xl font-bold" style={{ color }}>
        {n}
      </div>
      <div className="text-sm font-semibold mt-1" style={{ color }}>
        {label}
      </div>
    </div>
  );
}

export default async function Dashboard() {
  const [stocks, mouvements] = await Promise.all([
    getStocks(),
    getMouvements(),
  ]);
  const st = agregerStocks(stocks);
  const a = agregerMouvements(mouvements);
  const maxTop = a.top[0]?.total ?? 1;

  return (
    <div className="p-8 max-w-6xl mx-auto">
      <h1 className="text-3xl font-bold text-slate-900">Tableau de bord</h1>
      <p className="text-slate-500 mt-1">
        Vue d&apos;ensemble du stock en temps réel.
      </p>

      {/* Indicateurs */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mt-6">
        <Stat n={st.refs} label="Références" color="#2557D6" bg="#E7EEFB" />
        <Stat n={st.unites} label="Unités" color="#16357E" bg="#E7EEFB" />
        <Stat n={st.rupture} label="Ruptures" color="#E23D3D" bg="#FCE8E8" />
        <Stat n={st.faible} label="Faibles" color="#E8890C" bg="#FDF0DD" />
        <Stat n={st.ok} label="OK" color="#1E9E5A" bg="#E6F6EC" />
      </div>

      {/* Graphe + top */}
      <div className="grid lg:grid-cols-2 gap-6 mt-6">
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
          <h2 className="font-bold text-slate-900 mb-4">
            Consommation (7 derniers jours)
          </h2>
          <ConsoChart data={a.conso} />
        </div>

        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
          <h2 className="font-bold text-slate-900 mb-4">
            Produits les plus utilisés (ce mois)
          </h2>
          {a.top.length === 0 ? (
            <p className="text-slate-400 text-sm">Aucune sortie ce mois-ci.</p>
          ) : (
            <div className="flex flex-col gap-4">
              {a.top.map((t) => (
                <div key={t.nom}>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="font-medium text-slate-700 truncate pr-2">
                      {t.nom}
                    </span>
                    <span className="font-bold text-[#2557D6]">{t.total}</span>
                  </div>
                  <div className="h-2 rounded-full bg-slate-100 overflow-hidden">
                    <div
                      className="h-full rounded-full bg-[#2557D6]"
                      style={{ width: `${(t.total / maxTop) * 100}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
