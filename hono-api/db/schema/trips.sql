-- 旅行：下書き・予定・完了済みを同じテーブルで管理する。未定の値はNULL。
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
    destination text,
    duration_days integer CHECK (duration_days > 0),
    budget_per_person_jpy bigint
        CHECK (budget_per_person_jpy BETWEEN 0 AND 9007199254740991),
    preferences text[] NOT NULL DEFAULT '{}',
    CHECK (end_date >= start_date),
    CONSTRAINT trips_duration_matches_dates CHECK (
        start_date IS NULL OR end_date IS NULL
        OR (duration_days IS NOT NULL AND duration_days = end_date - start_date + 1)
    )
);

CREATE INDEX trips_user_start_date_idx ON trips(user_id, start_date, id);
