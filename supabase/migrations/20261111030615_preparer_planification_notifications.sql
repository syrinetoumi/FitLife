-- Les extensions seules n'activent aucun envoi ni travail récurrent.
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;
