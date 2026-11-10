import { createClient } from "npm:@supabase/supabase-js@2";
import { coordonneesValides, profils } from "./validation.ts";
import { cleCacheGeocodage, lireResultatsGeocodage, attributionGeocodage } from "./geocodage.ts";

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info", "Access-Control-Allow-Methods": "POST, OPTIONS" };
const reponse = (data, status = 200) => new Response(JSON.stringify(data), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") return reponse({ erreur: "Méthode refusée." }, 405);
  try {
    const url = Deno.env.get("SUPABASE_URL");
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anon = Deno.env.get("SUPABASE_ANON_KEY");
    if (!url || !service || !anon) return reponse({ erreur: "Configuration serveur manquante." }, 503);
    const admin = createClient(url, service, { auth: { persistSession: false } });
    const bearer = req.headers.get("Authorization") ?? "";
    if (!bearer.startsWith("Bearer ")) return reponse({ erreur: "Connexion requise." }, 401);
    // La vérification Auth valide le jeton ; les métadonnées utilisateur ne donnent aucun droit.
    const { data: { user }, error } = await admin.auth.getUser(bearer.slice(7));
    if (error || !user) return reponse({ erreur: "Connexion requise." }, 401);
    const { data: profil } = await admin.from("profiles").select("role,actif").eq("id", user.id).single();
    if (!profil?.actif) return reponse({ erreur: "Compte inactif." }, 403);
    const body = await req.json();
    if (body.action === "geocoder") {
      if (!["GESTIONNAIRE_ESPACE", "ADMIN"].includes(profil.role)) return reponse({ erreur: "Gestionnaire requis." }, 403);
      const recherche = typeof body.recherche === "string" ? body.recherche.trim().replace(/\s+/g, " ") : "";
      if (recherche.length < 3 || recherche.length > 250) return reponse({ erreur: "Adresse publique de 3 à 250 caractères requise." }, 400);
      const provider = Deno.env.get("GEOCODING_PROVIDER") ?? "nominatim";
      if (!["heigit", "nominatim"].includes(provider)) return reponse({ erreur: "Fournisseur de géocodage invalide." }, 503);
      const contact = Deno.env.get("GEOCODING_CONTACT_EMAIL");
      const base = Deno.env.get("GEOCODING_BASE_URL");
      const agent = Deno.env.get("GEOCODING_USER_AGENT");
      const key = Deno.env.get("OPENROUTESERVICE_API_KEY");
      if (provider === "heigit" ? !key : (!contact || !base || !agent)) return reponse({ erreur: "Géocodage non configuré sur le serveur." }, 503);
      // Le fournisseur fait partie de la clé du cache pour ne pas mélanger les sources et leurs attributions.
      const cle = await cleCacheGeocodage(provider, recherche);
      // Le verrou de la base limite les appels pour toutes les instances de la fonction.
      const { data: quota, error: erreurQuota } = await admin.rpc("preparer_geocodage", { p_recherche: cle });
      if (erreurQuota) return reponse({ erreur: "Cache de géocodage non configuré." }, 503);
      if (quota.cache) return reponse({ resultats: quota.cache, attribution: attributionGeocodage(quota.cache, provider) });
      if (quota.attendre) return reponse({ erreur: "Service occupé. Réessayez dans quelques secondes." }, 429);
      const endpoint = provider === "heigit" ? new URL("https://api.heigit.org/pelias/v1/search") : new URL(base!.replace(/\/$/, "") + "/search");
      if (endpoint.protocol !== "https:") return reponse({ erreur: "Configuration serveur invalide." }, 503);
      endpoint.search = (provider === "heigit" ? new URLSearchParams({ text: recherche, size: "5" })
        : new URLSearchParams({ q: recherche, format: "jsonv2", limit: "5", email: contact! })).toString();
      const upstream = await fetch(endpoint, {
        headers: provider === "heigit" ? { Authorization: key!, "Accept-Language": "fr" } : { "User-Agent": `${agent} (${contact})`, "Accept-Language": "fr" },
        signal: AbortSignal.timeout(12000),
      });
      if (!upstream.ok) {
        console.warn(`[geocodage] ${provider} HTTP ${upstream.status}`);
        return reponse({ erreur: "Géocodage temporairement indisponible." }, 502);
      }
      const resultats = lireResultatsGeocodage(await upstream.json(), provider);
      const { error: erreurCache } = await admin.rpc("memoriser_geocodage", { p_recherche: cle, p_resultat: resultats });
      if (erreurCache) return reponse({ erreur: "Sauvegarde du géocodage indisponible." }, 503);
      return reponse({ resultats, attribution: attributionGeocodage(resultats, provider) });
    }

    if (body.action === "itineraire") {
      if (!coordonneesValides(body.depart) || !Number.isSafeInteger(body.espace) || !profils.includes(body.profil)) return reponse({ erreur: "Départ, espace ou mode invalide." }, 400);
      // Le client normal utilise RLS pour autoriser la destination avant l’appel externe.
      const client = createClient(url, anon, { global: { headers: { Authorization: bearer } }, auth: { persistSession: false } });
      const { data: espace } = await client.from("espace_sportif").select("latitude,longitude").eq("id_espace", body.espace).single();
      if (!espace || !coordonneesValides([espace.longitude, espace.latitude])) return reponse({ erreur: "Destination inaccessible ou sans coordonnées." }, 400);
      const key = Deno.env.get("OPENROUTESERVICE_API_KEY");
      if (!key) return reponse({ erreur: "Calcul d’itinéraire non configuré sur le serveur." }, 503);
      const upstream = await fetch(`https://api.heigit.org/openrouteservice/v2/directions/${body.profil}/geojson`, {
        method: "POST", headers: { Authorization: key, "Content-Type": "application/json" },
        body: JSON.stringify({ coordinates: [body.depart, [espace.longitude, espace.latitude]] }), signal: AbortSignal.timeout(15000),
      });
      if (!upstream.ok) return reponse({ erreur: "Itinéraire indisponible pour ces points ou quota atteint." }, 502);
      const data = await upstream.json();
      const route = data.features?.[0];
      if (!route?.properties?.summary) return reponse({ erreur: "Aucun itinéraire trouvé." }, 404);
      return reponse({ distance: route.properties.summary.distance, duree: route.properties.summary.duration, geometrie: route.geometry, attribution: "openrouteservice · © OpenStreetMap contributors" });
    }
    return reponse({ erreur: "Action inconnue." }, 400);
  } catch (_) {
    // Ne jamais journaliser les clés, les jetons ou les adresses des utilisateurs.
    return reponse({ erreur: "Service de localisation indisponible." }, 502);
  }
});
