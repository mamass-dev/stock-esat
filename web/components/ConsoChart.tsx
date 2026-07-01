"use client";

import {
  Bar,
  BarChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

export default function ConsoChart({
  data,
}: {
  data: { jour: string; sorties: number }[];
}) {
  return (
    <ResponsiveContainer width="100%" height={220}>
      <BarChart data={data} margin={{ top: 10, right: 6, left: -20, bottom: 0 }}>
        <XAxis
          dataKey="jour"
          axisLine={false}
          tickLine={false}
          tick={{ fill: "#94a3b8", fontSize: 13 }}
        />
        <YAxis
          allowDecimals={false}
          axisLine={false}
          tickLine={false}
          tick={{ fill: "#94a3b8", fontSize: 13 }}
        />
        <Tooltip
          cursor={{ fill: "#f1f5f9" }}
          contentStyle={{
            borderRadius: 12,
            border: "none",
            boxShadow: "0 8px 24px rgba(0,0,0,0.08)",
          }}
          labelStyle={{ fontWeight: 600 }}
          formatter={(v) => [String(v), "Sorties"]}
        />
        <Bar dataKey="sorties" fill="#2557D6" radius={[8, 8, 0, 0]} maxBarSize={46} />
      </BarChart>
    </ResponsiveContainer>
  );
}
