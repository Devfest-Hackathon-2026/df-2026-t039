-- Agent：送信の再送管理と、旅行ごとの提案場所。会話本文はADKが別管理する。
-- 会話送信の再送対策と、同じ旅行での同時実行の防止。
CREATE TABLE agent_requests (
    user_id text NOT NULL REFERENCES users(id),
    client_message_id uuid NOT NULL,
    trip_id bigint NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    status text NOT NULL CHECK (status IN ('running', 'done', 'failed')),
    response jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, client_message_id)
);

-- 同じ旅行で実行中にできるのは1件だけ。違反時はAPIで409を返す。
CREATE UNIQUE INDEX agent_requests_one_running_per_trip
    ON agent_requests(trip_id) WHERE status = 'running';

-- Agent が Google Maps に基づいて提案した場所。採用時に place_id を引くために使う。
CREATE TABLE trip_suggested_places (
    user_id text NOT NULL,
    trip_id bigint NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    place_id bigint NOT NULL,
    suggested_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (trip_id, place_id),
    -- 複合外部キーにより、別ユーザーの場所を提案として記録することを禁止する。
    FOREIGN KEY (user_id, place_id) REFERENCES places(user_id, id) ON DELETE CASCADE
);

CREATE INDEX trip_suggested_places_trip_idx ON trip_suggested_places(trip_id, suggested_at DESC);
