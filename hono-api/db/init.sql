-- 空の新規DB専用。既存DBに実行しないでください。
-- psql -v ON_ERROR_STOP=1 -f db/init.sql
-- 種類別の定義から現在のDB構成を作成する。
\set ON_ERROR_STOP on
BEGIN;
\ir schema/users.sql
\ir schema/trips.sql
\ir schema/places.sql
\ir schema/trip_items.sql
\ir schema/saved_places.sql
\ir schema/agent.sql
\ir schema/rules.sql
COMMIT;
