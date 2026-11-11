-- Exécuter uniquement après configuration, migration et déploiement du worker.
-- Activer pg_cron et pg_net dans Supabase avant d'exécuter ce fichier.
-- Créer dans Vault les secrets fitlife_notifications_url et fitlife_notifications_secret.
-- L'URL doit être https://<project-ref>.supabase.co/functions/v1/espaces-notifications.
-- Le second secret doit correspondre à NOTIFICATIONS_WORKER_SECRET du worker.
-- Le travail est créé inactif ; son activation est une étape distincte.
begin;
do $$
begin
  if not exists (select 1 from vault.decrypted_secrets where name='fitlife_notifications_url')
    or not exists (select 1 from vault.decrypted_secrets where name='fitlife_notifications_secret') then
    raise exception 'Configurez les deux secrets Vault avant de planifier les notifications.';
  end if;
end $$;

select cron.schedule('fitlife-notifications-espaces', '* * * * *', $travail$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name='fitlife_notifications_url'),
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'x-worker-secret',(select decrypted_secret from vault.decrypted_secrets where name='fitlife_notifications_secret')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 240000
  );
$travail$);

select cron.alter_job(jobid, active := false)
from cron.job where jobname='fitlife-notifications-espaces';
commit;

-- Après configuration Brevo et autorisation de l'envoi :
-- select cron.alter_job(jobid, active := true)
-- from cron.job where jobname='fitlife-notifications-espaces';
