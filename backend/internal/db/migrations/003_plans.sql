-- +goose Up
CREATE TABLE workout_plans (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

CREATE TABLE workout_days (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id     UUID NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

CREATE TABLE planned_exercises (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    day_id        UUID NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
    exercise_id   TEXT NOT NULL REFERENCES exercises(id),
    sets          SMALLINT NOT NULL,
    reps          SMALLINT NOT NULL,
    target_weight NUMERIC(6,2),
    position      SMALLINT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ
);

-- +goose Down
DROP TABLE planned_exercises;
DROP TABLE workout_days;
DROP TABLE workout_plans;
