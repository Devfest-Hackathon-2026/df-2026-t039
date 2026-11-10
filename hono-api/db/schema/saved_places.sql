-- 保存場所：ユーザーと場所の関係。解除時に場所・旅程は削除しない。
CREATE TABLE saved_places (
    user_id text NOT NULL REFERENCES users(id),
    place_id bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, place_id),
    FOREIGN KEY (user_id, place_id) REFERENCES places(user_id, id)
        ON DELETE CASCADE
);

CREATE INDEX saved_places_place_id_idx ON saved_places(place_id);
