export const profils = ["foot-walking", "cycling-regular", "driving-car"];
export function coordonneesValides(point) {
  return Array.isArray(point) && point.length === 2 &&
    point.every((v) => typeof v === "number" && Number.isFinite(v)) &&
    Math.abs(point[0]) <= 180 && Math.abs(point[1]) <= 90;
}
