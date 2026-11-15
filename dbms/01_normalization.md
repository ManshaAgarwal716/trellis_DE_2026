# Database normalization

> **Assumption:** No application code or schema was present in the AP workspace when this document was written. The example below models a simple project and task tracking app. Replace the entities and dependencies with the app's actual data model when it is available.

## Data and business rules

The app stores users, projects, project membership, tasks, and task assignments. A user can belong to many projects, a project can have many users and tasks, and a task can have many assignees. Each task belongs to exactly one project. A user's email and a project's name are unique within the app; task titles need not be unique.

The main functional dependencies are:

- `user_id → user_name, email`
- `email → user_id, user_name`
- `project_id → project_name, owner_user_id`
- `project_name → project_id, owner_user_id`
- `task_id → project_id, task_title, status, due_date`
- `(project_id, member_user_id) → joined_at`
- `(task_id, assignee_user_id) → assigned_at`

## First normal form (1NF)

Start with one row per task, project member, and task assignee. Every field contains a single value, so there are no comma-separated member or assignee lists:

```text
TaskProjectRow(
  project_id, project_name, owner_user_id, owner_name, owner_email,
  member_user_id, member_name, member_email, joined_at,
  task_id, task_title, status, due_date,
  assignee_user_id, assignee_name, assignee_email, assigned_at
)
```

This relation is in 1NF, but the Cartesian combination of members and assignees repeats project and task facts. It also cannot represent a project with no tasks without nulls. A possible key for populated rows is `(task_id, member_user_id, assignee_user_id)`.

## Second normal form (2NF)

Split facts that depend on only part of that composite key. Task facts depend on `task_id`; membership facts depend on `(project_id, member_user_id)`; assignment facts depend on `(task_id, assignee_user_id)`:

```text
Task_2NF(task_id PK, project_id, project_name, owner_user_id,
         owner_name, owner_email, task_title, status, due_date)
ProjectMember_2NF(project_id, member_user_id, member_name,
                  member_email, joined_at,
                  PK(project_id, member_user_id))
TaskAssignment_2NF(task_id, assignee_user_id, assignee_name,
                   assignee_email, assigned_at,
                   PK(task_id, assignee_user_id))
```

Each non-key attribute now depends on the whole key of its relation. Repeated user and project details still cause update anomalies because they depend transitively on IDs rather than on the relation's key directly.

## Third normal form (3NF)

Move user and project details into their own relations, removing the transitive dependencies:

```text
User(user_id PK, user_name, email UNIQUE)
Project(project_id PK, project_name UNIQUE,
        owner_user_id FK → User.user_id)
ProjectMember(project_id FK → Project.project_id,
              member_user_id FK → User.user_id, joined_at,
              PK(project_id, member_user_id))
Task(task_id PK, project_id FK → Project.project_id,
     task_title, status, due_date)
TaskAssignment(task_id FK → Task.task_id,
               assignee_user_id FK → User.user_id, assigned_at,
               PK(task_id, assignee_user_id))
```

All non-key attributes depend on a key, the whole key, and no non-key attribute. A user email is stored once, and project membership and task assignment are independent relationships. Foreign keys preserve the links between the relations.

## Boyce–Codd normal form (BCNF)

Under the stated business rules, this 3NF design also satisfies BCNF: every determinant listed above is a candidate key in its own relation. `email` and `project_name` are alternate candidate keys because they are unique. If those uniqueness rules do not hold in the real app, remove the corresponding `UNIQUE` constraints; the ID-based relations still satisfy BCNF.
