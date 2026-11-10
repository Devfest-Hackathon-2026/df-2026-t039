-- 共通ルール：更新日時、旅程の所有者整合、所有者変更の禁止。
-- 旅行削除時の場所の自動削除は行わない（場所・保存関係は独立して保持）。
-- 更新された行のupdated_atを自動更新します。
CREATE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := clock_timestamp();
    RETURN NEW;
END;
$$;

CREATE TRIGGER users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trips_updated_at
BEFORE UPDATE ON trips
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER places_updated_at
BEFORE UPDATE ON places
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trip_items_updated_at
BEFORE UPDATE ON trip_items
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 予定から別ユーザーの場所を参照することを禁止します。
-- ログインユーザーの認証・アクセス制御は別途API側で行います。
CREATE FUNCTION check_item_owner()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    trip_owner text;
    place_owner text;
BEGIN
    IF NEW.place_id IS NOT NULL THEN
        SELECT user_id INTO trip_owner
        FROM trips WHERE id = NEW.trip_id;

        SELECT user_id INTO place_owner
        FROM places WHERE id = NEW.place_id;

        IF trip_owner IS DISTINCT FROM place_owner THEN
            RAISE EXCEPTION
                '旅行と場所の所有ユーザーが異なります';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trip_items_owner
BEFORE INSERT OR UPDATE OF trip_id, place_id ON trip_items
FOR EACH ROW EXECUTE FUNCTION check_item_owner();

-- 既存の予定と場所の整合性を保つため、所有者変更を禁止します。
CREATE FUNCTION prevent_owner_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.user_id IS DISTINCT FROM OLD.user_id THEN
        RAISE EXCEPTION '所有ユーザーは変更できません';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trips_owner_immutable
BEFORE UPDATE OF user_id ON trips
FOR EACH ROW EXECUTE FUNCTION prevent_owner_change();

CREATE TRIGGER places_owner_immutable
BEFORE UPDATE OF user_id ON places
FOR EACH ROW EXECUTE FUNCTION prevent_owner_change();
