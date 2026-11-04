import assert from "node:assert/strict";
import {coordonneesValides, profils} from "../functions/espaces-localisation/validation.ts";
assert.equal(coordonneesValides([10.2,36.8]),true);
for (const p of [[181,0],[0,91],[NaN,0],["10",36],[10],null]) assert.equal(coordonneesValides(p),false);
assert.deepEqual(profils,["foot-walking","cycling-regular","driving-car"]);
console.log("Location coordinate and travel profile checks passed.");

const {cleCacheGeocodage,lireResultatsGeocodage,attributionGeocodage}=await import("../functions/espaces-localisation/geocodage.ts");
const resultats=lireResultatsGeocodage({features:[{properties:{label:"Tunis",source:"whosonfirst"},geometry:{coordinates:[10.2,36.8]}}]},"heigit");
assert.equal(resultats[0].latitude,36.8);
assert.match(attributionGeocodage(resultats,"heigit"),/Who's On First/);
assert.notEqual(await cleCacheGeocodage("heigit","Tunis"),await cleCacheGeocodage("nominatim","Tunis"));
console.log("Geocoding adapter and provider cache checks passed.");
