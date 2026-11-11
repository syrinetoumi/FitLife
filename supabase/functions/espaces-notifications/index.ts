import { createClient } from "npm:@supabase/supabase-js@2.119.0";

// Aucun destinataire ni contenu n'est accepté du client : tout vient de la file privée.
Deno.serve(async (req) => {
  const reponse = (body: object, status = 200) => Response.json(body, { status });
  if (req.method !== "POST") return reponse({ erreur: "Méthode refusée." }, 405);
  const secret = Deno.env.get("NOTIFICATIONS_WORKER_SECRET");
  if (!secret || req.headers.get("x-worker-secret") !== secret) {
    return reponse({ erreur: "Accès refusé." }, 401);
  }
  if (Deno.env.get("BREVO_SENDING_ENABLED") !== "true") {
    return reponse({ erreur: "Envoi des e-mails désactivé." }, 503);
  }
  const url = Deno.env.get("SUPABASE_URL");
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const cle = Deno.env.get("BREVO_API_KEY");
  const emailExpediteur = Deno.env.get("BREVO_SENDER_EMAIL");
  const nomExpediteur = Deno.env.get("BREVO_SENDER_NAME") || "FitLife";
  if (!url || !service || !cle || !emailExpediteur) {
    return reponse({ erreur: "Configuration des notifications incomplète." }, 503);
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
          const resultat = await fetch("https://api.brevo.com/v3/smtp/email", {
            method: "POST",
            headers: { "api-key": cle, "Content-Type": "application/json", "Accept": "application/json" },
            signal: AbortSignal.timeout(10000),
            body: JSON.stringify({
              sender: { email: emailExpediteur, name: nomExpediteur },
              to: [{ email: notification.email }],
              subject: confirmation ? "FitLife — Souscription confirmée" : "FitLife — Votre abonnement expire bientôt",
              textContent: contenu,
              headers: { idempotencyKey: notification.id },
              tags: ["espaces-sportifs", confirmation ? "confirmation" : "expiration"],
            }),
          });
          code = `HTTP_${resultat.status}`;
          const corps = await resultat.json().catch(() => null);
          if (resultat.ok) {
            if (typeof corps?.messageId === "string" && corps.messageId.length > 0) {
              etat = "ACCEPTEE";
              message = corps.messageId;
            } else {
              code = "REPONSE_INCOMPLETE";
            }
          } else if (resultat.status === 400 && corps?.code === "duplicate_parameter") {
            // Brevo confirme que cette clé a déjà été traitée ; ne pas renvoyer cet e-mail.
            etat = "ACCEPTEE";
            code = "DOUBLON_ACCEPTE";
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
