-- +goose Up
CREATE INDEX idx_workout_plans_user_id ON workout_plans(user_id);

CREATE INDEX idx_workout_days_plan_id ON workout_days(plan_id);

CREATE INDEX idx_planned_exercises_day_id ON planned_exercises(day_id);
CREATE INDEX idx_planned_exercises_exercise_id ON planned_exercises(exercise_id);

CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_plan_id ON workout_sessions(plan_id);
CREATE INDEX idx_workout_sessions_day_id ON workout_sessions(day_id);

CREATE INDEX idx_set_logs_session_id ON set_logs(session_id);
CREATE INDEX idx_set_logs_exercise_id ON set_logs(exercise_id);

-- +goose Down
DROP INDEX idx_workout_plans_user_id;

DROP INDEX idx_workout_days_plan_id;

DROP INDEX idx_planned_exercises_day_id;
DROP INDEX idx_planned_exercises_exercise_id;

DROP INDEX idx_workout_sessions_user_id;
DROP INDEX idx_workout_sessions_plan_id;
DROP INDEX idx_workout_sessions_day_id;

DROP INDEX idx_set_logs_session_id;
DROP INDEX idx_set_logs_exercise_id;
