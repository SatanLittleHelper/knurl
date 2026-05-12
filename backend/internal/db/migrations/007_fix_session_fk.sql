-- +goose Up
ALTER TABLE workout_sessions
    DROP CONSTRAINT workout_sessions_plan_id_fkey,
    ADD CONSTRAINT workout_sessions_plan_id_fkey
        FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE SET NULL;

ALTER TABLE workout_sessions
    DROP CONSTRAINT workout_sessions_day_id_fkey,
    ADD CONSTRAINT workout_sessions_day_id_fkey
        FOREIGN KEY (day_id) REFERENCES workout_days(id) ON DELETE SET NULL;

-- +goose Down
ALTER TABLE workout_sessions
    DROP CONSTRAINT workout_sessions_plan_id_fkey,
    ADD CONSTRAINT workout_sessions_plan_id_fkey
        FOREIGN KEY (plan_id) REFERENCES workout_plans(id);

ALTER TABLE workout_sessions
    DROP CONSTRAINT workout_sessions_day_id_fkey,
    ADD CONSTRAINT workout_sessions_day_id_fkey
        FOREIGN KEY (day_id) REFERENCES workout_days(id);
