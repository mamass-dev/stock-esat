// Génère une référence lisible à partir d'un nom.
// "Détergent sol 5L" -> "DETERGENT-SOL-5L"
export function genererRef(nom: string): string {
  let s = nom.trim().toUpperCase();
  const from = "ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ";
  const to = "AAAAAACEEEEIIIINOOOOOUUUUY";
  for (let i = 0; i < from.length; i++) {
    s = s.split(from[i]).join(to[i]);
  }
  return s.replace(/[^A-Z0-9]+/g, "-").replace(/^-+|-+$/g, "");
}
