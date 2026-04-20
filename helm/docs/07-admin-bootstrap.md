# Initial Setup: Create Your Organization

After deploying the stack, create your first organization using the CLI.

## Prerequisites

1. The stack must be running (`task up` + `task wait`)
2. At least one user must have signed in to the application

## 1) Promote Yourself to Admin

```bash
task admin:grant -- <your-email-or-user-id>
```

`task admin:grant`, `task admin:psql`, and `task org:create` target the application database `gitai` by default.
If you changed `postgresql.auth.database`, run them with `APP_DB_NAME=<your-db>`.

This grants your user the `admin` role, which is required to own an organization
and gives access to the `/admin` panel for system-wide management.

## 2) Create an Organization

```bash
task org:create
```

This interactive command will:
- List all site admin users
- Ask you to select the org owner
- Ask for the organization name
- Create the org in the database with the selected admin as owner

Only admin users are shown as eligible org owners. If you need to create an org
for another user, promote them to admin first with `task admin:grant`.

We recommend creating a single organization for your entire company. One org can
connect multiple SCM providers (GitHub, GitLab, Bitbucket) and manage all
repositories in one place. You can run this command again to create additional
organizations if needed, but most deployments only need one.

## Re-enabling Self-Service Org Creation

By default, `DISABLE_ORG_CREATION=true` prevents users from creating organizations
through the UI or API. If you want to allow users to create their own organizations
(not recommended for most self-hosted deployments), set:

```yaml
# In your values override (e.g., generated/values.local.yaml)
app:
  disableOrgCreation: false
```

We recommend keeping org creation disabled and using `task org:create` for all
org provisioning, as it gives administrators full control over the tenant structure.
