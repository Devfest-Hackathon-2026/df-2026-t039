-- 旅程：観光・食事・宿泊・移動。日番号未定の予定も保持する。
-- place_idは移動の到着先、それ以外は訪問先。費用は円/人。NULLは未定、0は無料。
-- scheduled_date/start_at/end_atは旧データ互換用。新規処理では日番号と時刻を使う。
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
    day_number integer CHECK (day_number >= 1),
    title text,
    start_time time without time zone,
    end_time time without time zone,
    end_day_offset integer NOT NULL DEFAULT 0 CHECK (end_day_offset >= 0),
    notes text,
    CONSTRAINT trip_items_time_order CHECK (
        start_time IS NULL OR end_time IS NULL
        OR end_day_offset > 0 OR end_time >= start_time
    ),
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

COMMENT ON COLUMN trip_items.scheduled_date IS '旧データ保持用。新規実装では開始日とday_numberから算出する';
COMMENT ON COLUMN trip_items.start_at IS '旧データ保持用。新規実装ではday_numberとstart_timeを使用する';
COMMENT ON COLUMN trip_items.end_at IS '旧データ保持用。新規実装ではend_timeとend_day_offsetを使用する';
COMMENT ON COLUMN trip_items.end_day_offset IS '開始日に対する終了日の差。翌日終了なら1';

CREATE INDEX trip_items_trip_day_order_idx ON trip_items(trip_id, day_number, sort_order);
CREATE INDEX trip_items_place_id_idx ON trip_items(place_id);
