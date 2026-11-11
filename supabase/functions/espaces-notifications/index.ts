import { createClient } from "npm:@supabase/supabase-js@2.119.0";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const reponse = (body: object, status = 200) => Response.json(body, { status, headers: cors });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") return reponse({ erreur: "Méthode refusée." }, 405);
  const url = Deno.env.get("SUPABASE_URL");
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !service) return reponse({ erreur: "Configuration serveur incomplète." }, 503);
  const client = createClient(url, service, { auth: { persistSession: false } });
  const secret = Deno.env.get("NOTIFICATIONS_WORKER_SECRET");
  const worker = !!secret && req.headers.get("x-worker-secret") === secret;
  let utilisateur: string | null = null;
  if (!worker) {
    const bearer = req.headers.get("Authorization") ?? "";
    if (!bearer.startsWith("Bearer ")) return reponse({ erreur: "Connexion requise." }, 401);
    const { data: { user }, error } = await client.auth.getUser(bearer.slice(7));
    if (error || !user) return reponse({ erreur: "Connexion requise." }, 401);
    const { data: profil, error: lecture } = await client.from("profiles").select("actif").eq("id", user.id).maybeSingle();
    if (lecture || !profil?.actif) return reponse({ erreur: "Compte inactif." }, 403);
    utilisateur = user.id;
  }
  const cle = Deno.env.get("NOVU_API_KEY");
  const base = Deno.env.get("NOVU_API_URL") || "https://api.novu.co";
  const workflow = Deno.env.get("NOVU_WORKFLOW_ID") || "fitlife-subscription-confirmed";
  if (!cle || !["https://api.novu.co", "https://eu.api.novu.co"].includes(base) || Deno.env.get("NOVU_ENABLED") !== "true") {
    return reponse({ erreur: "Les notifications ne sont pas encore configurées." }, 503);
  }
  const appeler = async (path: string, method = "GET", body?: object, idempotence?: string) => {
    const resultat = await fetch(base + path, {
      method,
      headers: { Authorization: `ApiKey ${cle}`, "Content-Type": "application/json", ...(idempotence ? { "Idempotency-Key": idempotence } : {}) },
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: AbortSignal.timeout(10000),
    });
    return { status: resultat.status, ok: resultat.ok, data: await resultat.json().catch(() => null) };
  };
  try {
    const body = await req.json().catch(() => ({}));
    const action = worker ? "synchroniser" : body.action;
    if (!["lister", "lire", "synchroniser"].includes(action)) return reponse({ erreur: "Action invalide." }, 400);
    if (action === "synchroniser") {
      // Les destinataires sont issus de la transaction serveur, jamais du corps client.
      const { data: travaux, error } = await client.rpc("reclamer_confirmations_novu", { p_destinataire: utilisateur, p_limite: 20 });
      if (error) throw error;
      let acceptees = 0;
      for (const travail of travaux ?? []) {
        let etat = "EN_ATTENTE", code = "RESEAU";
        let message: string | null = null;
        try {
          const { data: notification, error: preparation } = await client.rpc("preparer_notification_espace", { p_id: travail.id, p_bail: travail.bail });
          if (preparation) throw preparation;
          if (!notification) {
            etat = "IGNOREE"; code = "INVALIDE";
          } else {
            const resultat = await appeler("/v1/events/trigger", "POST", {
              name: workflow, to: { subscriberId: notification.subscriber_id },
              payload: { message: "Votre souscription est confirmée." }, transactionId: notification.id,
            }, notification.id);
            code = `HTTP_${resultat.status}`;
            const donnees = resultat.data?.data ?? resultat.data;
            if (resultat.ok && donnees?.acknowledged === true) {
              etat = "ACCEPTEE"; message = notification.id; acceptees++;
            } else if (resultat.status === 422) {
              etat = "A_VERIFIER";
            }
          }
        } catch (_) { /* Le bail et l'idempotence autorisent une reprise sûre. */ }
        const { error: fin } = await client.rpc("terminer_notification_espace", {
          p_id: travail.id, p_bail: travail.bail, p_etat: etat, p_code: code, p_message: message,
        });
        if (fin) throw fin;
      }
      return reponse({ acceptees });
    }
    // Chaque opération est limitée au subscriber correspondant au JWT vérifié.
    const chemin = `/v2/subscribers/${encodeURIComponent(utilisateur!)}/notifications`;
    if (action === "lire") {
      if (typeof body.id !== "string" || !/^[a-zA-Z0-9_-]{1,128}$/.test(body.id)) return reponse({ erreur: "Notification invalide." }, 400);
      const resultat = await appeler(`${chemin}/${encodeURIComponent(body.id)}/read`, "PATCH");
      if (!resultat.ok) return reponse({ erreur: "Impossible de marquer la notification comme lue." }, 502);
      return reponse({ lu: true });
    }
    const resultat = await appeler(`${chemin}?limit=50&archived=false&tags=fitlife-confirmation`);
    if (resultat.status === 404) return reponse({ notifications: [], non_lues: 0 });
    if (!resultat.ok) throw new Error(`NOVU_INBOX_HTTP_${resultat.status}`);
    const donnees = resultat.data?.data;
    // Novu renvoie les listes directement dans data ; certains contrats OpenAPI
    // décrivent une enveloppe data supplémentaire. Accepter les deux formes.
    const liste = Array.isArray(donnees) ? donnees : donnees?.data;
    if (!Array.isArray(liste)) throw new Error("NOVU_INBOX_FORMAT");
    const notifications = liste.map((n: any) => ({
      id: n.id, titre: n.subject || "Souscription confirmée", texte: n.body || "Votre souscription est confirmée.",
      lu: n.isRead === true, cree_le: n.createdAt,
    }));
    const filtres = encodeURIComponent(JSON.stringify([{ read: false, archived: false, tags: ["fitlife-confirmation"] }]));
    const compte = await appeler(`${chemin}/count?filters=${filtres}`);
    if (!compte.ok) throw new Error(`NOVU_COMPTE_HTTP_${compte.status}`);
    const comptes = Array.isArray(compte.data) ? compte.data
      : Array.isArray(compte.data?.data) ? compte.data.data : compte.data?.data?.data;
    if (!Array.isArray(comptes)) throw new Error("NOVU_COMPTE_FORMAT");
    return reponse({ notifications, non_lues: comptes[0]?.count ?? 0 });
  } catch (erreur) {
    // Codes techniques seulement : aucun identifiant, contenu, destinataire ou secret.
    const code = erreur instanceof Error && /^NOVU_[A-Z_0-9]+$/.test(erreur.message)
      ? erreur.message : "TRAITEMENT";
    console.warn(`[notifications] ${code}`);
    return reponse({ erreur: "Notifications indisponibles. Réessayez dans un instant." }, 502);
  }
});
