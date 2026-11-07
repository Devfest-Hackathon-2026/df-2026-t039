-- 場所情報：旅程や保存場所から参照する。ここに存在するだけでは保存済みにならない。
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
    UNIQUE (user_id, google_place_id),
    CONSTRAINT places_user_id_id_key UNIQUE (user_id, id)
);
