-- Project and task tracking schema described in 01_normalization.md.
-- Run with PostgreSQL: psql -v ON_ERROR_STOP=1 -f dbms/03_schema.sql

CREATE TABLE app_users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE
);

CREATE TABLE projects (
    project_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_name TEXT NOT NULL UNIQUE,
    owner_user_id BIGINT NOT NULL REFERENCES app_users (user_id)
);

CREATE TABLE project_members (
    project_id BIGINT NOT NULL REFERENCES projects (project_id) ON DELETE CASCADE,
    member_user_id BIGINT NOT NULL REFERENCES app_users (user_id),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id, member_user_id)
);

CREATE TABLE tasks (
    task_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id BIGINT NOT NULL REFERENCES projects (project_id) ON DELETE CASCADE,
    task_title TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'todo'
        CHECK (status IN ('todo', 'in_progress', 'done')),
    due_date DATE
);

CREATE TABLE task_assignments (
    task_id BIGINT NOT NULL REFERENCES tasks (task_id) ON DELETE CASCADE,
    assignee_user_id BIGINT NOT NULL REFERENCES app_users (user_id),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (task_id, assignee_user_id)
);

CREATE INDEX project_members_member_user_id_idx
    ON project_members (member_user_id);
CREATE INDEX tasks_project_id_idx
    ON tasks (project_id);
CREATE INDEX task_assignments_assignee_user_id_idx
    ON task_assignments (assignee_user_id);
