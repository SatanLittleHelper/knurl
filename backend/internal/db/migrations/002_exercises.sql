-- +goose Up
CREATE TABLE exercises (
    id            TEXT PRIMARY KEY,
    name          TEXT NOT NULL,
    muscle_group  TEXT NOT NULL,
    equipment     TEXT,
    instructions  TEXT,
    gif_url       TEXT,
    cached_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- +goose Down
DROP TABLE exercises;
