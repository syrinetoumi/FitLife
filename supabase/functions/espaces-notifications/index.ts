import { createClient } from "npm:@supabase/supabase-js@2.119.0";

// Aucun destinataire ni contenu n'est accepté du client : tout vient de la file privée.
Deno.serve(async (req) => {
  const reponse = (body: object, status = 200) => Response.json(body, { status });
  if (req.method !== "POST") return reponse({ erreur: "Méthode refusée." }, 405);
  const secret = Deno.env.get("NOTIFICATIONS_WORKER_SECRET");
  if (!secret || req.headers.get("x-worker-secret") !== secret) {
    return reponse({ erreur: "Accès refusé." }, 401);
  }
  if (Deno.env.get("EMAIL_SENDING_ENABLED") !== "true") {
    return reponse({ erreur: "Envoi des e-mails désactivé." }, 503);
  }
  const url = Deno.env.get("SUPABASE_URL");
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const cle = Deno.env.get("RESEND_API_KEY");
  const emailExpediteur = Deno.env.get("RESEND_SENDER_EMAIL");
  const nomExpediteur = Deno.env.get("RESEND_SENDER_NAME") || "FitLife";
  const destinataireAutorise = Deno.env.get("RESEND_ALLOWED_RECIPIENT")?.trim().toLowerCase();
  if (!url || !service || !cle || !emailExpediteur) {
    return reponse({ erreur: "Configuration des notifications incomplète." }, 503);
  }
  if (emailExpediteur.endsWith("@resend.dev") && !destinataireAutorise) {
    return reponse({ erreur: "Destinataire de démonstration non configuré." }, 503);
  }
  const client = createClient(url, service, { auth: { persistSession: false } });
  try {
    const { data: travaux, error } = await client.rpc("reclamer_notifications_espaces", { p_limite: 20 });
    if (error) throw error;
    const bilan = { acceptees: 0, ignorees: 0, a_reessayer: 0 };
    for (const travail of travaux ?? []) {
      let etat = "EN_ATTENTE";
      let code = "RESEAU";
      let message: string | null = null;
      try {
        const { data: notification, error: preparation } = await client.rpc("preparer_notification_espace", {
          p_id: travail.id, p_bail: travail.bail,
        });
        if (preparation) throw preparation;
        if (!notification) {
          etat = "IGNOREE";
          code = "INVALIDE";
        } else if (destinataireAutorise && notification.email.trim().toLowerCase() !== destinataireAutorise) {
          etat = "IGNOREE";
          code = "DESTINATAIRE_RESTREINT";
        } else {
          const confirmation = notification.nature === "CONFIRMATION";
          const texte = confirmation
            ? "Votre souscription est confirmée."
            : "Votre abonnement arrive à échéance dans trois jours.";
          // Le texte brut évite d'interpréter comme HTML les noms saisis par les gestionnaires.
          const contenu = [
            texte,
            `Espace : ${notification.espace}`,
            `Offre : ${notification.offre}`,
            `Validité : du ${notification.date_debut} au ${notification.date_fin}`,
            `Montant à la souscription : ${notification.montant} TND`,
            "Consultez votre abonnement dans l’application FitLife.",
          ].join("\n\n");
          const resultat = await fetch("https://api.resend.com/emails", {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${cle}`, "Content-Type": "application/json",
              "Idempotency-Key": notification.id,
            },
            signal: AbortSignal.timeout(10000),
            body: JSON.stringify({
              from: `${nomExpediteur} <${emailExpediteur}>`,
              to: [notification.email],
              subject: confirmation ? "FitLife — Souscription confirmée" : "FitLife — Votre abonnement expire bientôt",
              text: contenu,
              tags: [{ name: "module", value: "espaces-sportifs" }, { name: "nature", value: confirmation ? "confirmation" : "expiration" }],
            }),
          });
          code = `HTTP_${resultat.status}`;
          const corps = await resultat.json().catch(() => null);
          if (resultat.ok) {
            if (typeof corps?.id === "string" && corps.id.length > 0) {
              etat = "ACCEPTEE";
              message = corps.id;
            } else {
              code = "REPONSE_INCOMPLETE";
            }
          } else if (resultat.status === 409 && corps?.name === "invalid_idempotent_request") {
            // Un contenu modifié sous une clé existante demande une vérification manuelle.
            etat = "A_VERIFIER";
            code = "CONFLIT_IDEMPOTENCE";
          }
        }
      } catch (_) {
        // Le même identifiant d'idempotence sera conservé au prochain essai.
      }
      const { error: fin } = await client.rpc("terminer_notification_espace", {
        p_id: travail.id, p_bail: travail.bail, p_etat: etat, p_code: code, p_message: message,
      });
      if (fin) throw fin;
      if (etat === "ACCEPTEE") bilan.acceptees++;
      else if (etat === "IGNOREE") bilan.ignorees++;
      else bilan.a_reessayer++;
    }
    return reponse(bilan);
  } catch (_) {
    return reponse({ erreur: "Traitement interrompu. Les événements réservés seront repris." }, 500);
  }
});
