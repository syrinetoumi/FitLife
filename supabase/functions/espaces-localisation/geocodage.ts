import { coordonneesValides } from "./validation.ts";

export async function cleCacheGeocodage(provider, recherche) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(provider + ":" + recherche.toLocaleLowerCase("fr")));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

// Les deux formats fournisseurs sont convertis vers le même format utilisé par Flutter.
export function lireResultatsGeocodage(data, provider) {
  const resultats = provider === "heigit"
    ? data.features.map((r) => ({ nom: r.properties.label, latitude: r.geometry.coordinates[1], longitude: r.geometry.coordinates[0], source: r.properties.source }))
    : data.map((r) => ({ nom: r.display_name, latitude: Number(r.lat), longitude: Number(r.lon), source: "openstreetmap" }));
  return resultats.filter((r) => typeof r.nom === "string" && coordonneesValides([r.longitude, r.latitude]));
}

export function attributionGeocodage(resultats, provider) {
  const libelles = { openstreetmap: "© OpenStreetMap contributors · ODbL", whosonfirst: "Who's On First", geonames: "GeoNames · CC BY 4.0", openaddresses: "OpenAddresses" };
  const sources = [...new Set(resultats.map((r) => r.source).filter(Boolean))];
  return (provider === "heigit" ? "HeiGIT/Pelias · " : "") + sources.map((s) => libelles[s] ?? s).join(" · ");
}
