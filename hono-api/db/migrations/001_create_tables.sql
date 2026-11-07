-- 新規DB用。既に手動作成済みのDBには再実行しないでください。
-- 001 → 002 の順番で、エラー時に停止する設定で実行してください。
BEGIN;

-- Firebase AuthenticationのUIDを主キーとして保存します。
CREATE TABLE users (
    id text PRIMARY KEY,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE trips (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id text NOT NULL REFERENCES users(id),
    name text,
    start_date date,
    end_date date,
    participant_count integer CHECK (participant_count > 0),
    status text NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'planned', 'completed')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (end_date >= start_date)
);

CREATE TABLE places (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id text NOT NULL REFERENCES users(id),
    google_place_id text,
    name text NOT NULL,
    address text,
    latitude numeric(9,6)
        CHECK (latitude BETWEEN -90 AND 90),
    longitude numeric(9,6)
        CHECK (longitude BETWEEN -180 AND 180),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, google_place_id)
);

-- place_idは、移動の場合は到着先、それ以外では訪問先です。
-- 費用は一人当たりの日本円。NULLは未定、0は無料です。
CREATE TABLE trip_items (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trip_id bigint NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    type text NOT NULL
        CHECK (type IN ('sightseeing', 'meal', 'accommodation', 'transport')),
    sort_order integer NOT NULL CHECK (sort_order >= 1),
    place_id bigint REFERENCES places(id),
    scheduled_date date,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    estimated_cost_per_person bigint
        CHECK (estimated_cost_per_person >= 0),
    transport_mode text
        CHECK (transport_mode IN (
            'walking', 'train', 'bus', 'car',
            'taxi', 'airplane', 'boat', 'other'
        )),
    estimated_travel_minutes integer
        CHECK (estimated_travel_minutes >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (trip_id, sort_order) DEFERRABLE INITIALLY IMMEDIATE,
    CHECK (end_at >= start_at),
    CHECK (
        type = 'transport'
        OR (
            transport_mode IS NULL
            AND estimated_travel_minutes IS NULL
        )
    )
);

COMMIT;
