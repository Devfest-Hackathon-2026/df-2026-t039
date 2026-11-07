-- ユーザー：Firebase Authentication の UID を主キーにする。
CREATE TABLE users (
    id text PRIMARY KEY,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
