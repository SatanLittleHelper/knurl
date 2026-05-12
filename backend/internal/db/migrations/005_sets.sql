-- +goose Up
CREATE TABLE set_logs (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id   UUID NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
    exercise_id  TEXT NOT NULL REFERENCES exercises(id),
    set_number   SMALLINT NOT NULL,
    reps         SMALLINT NOT NULL,
    weight       NUMERIC(6,2),
    completed_at TIMESTAMPTZ NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ
);

-- +goose Down
DROP TABLE set_logs;
