# Quickstart

## 1) Initialize

```bash
task init
```

Optional all-in-one first run:

```bash
task bootstrap
```

## 2) Set Required Environment Values

Edit `.env`:

- `WEB_BASE_URL`
- `BETTER_AUTH_URL`
- `LICENSE_KEY`

## 3) Configure SCM Apps

```bash
task scm:configure
```

The wizard lets you enable GitHub, GitLab, and Bitbucket independently.
GitHub is optional.
If all are skipped, it exits with an error because at least one SCM is required.
Keep the default slug unless you run multiple instances of the same provider: `github`, `gitlab`, `bitbucket`.

## 4) Start Stack

```bash
task up
task wait
```

This starts infra + app containers, and runs one-shot migrators automatically.

## 5) Verify

```bash
task doctor
task status
```

Optional dashboard check:

```bash
curl -I http://localhost:3001
```

## 6) Promote Yourself to Admin and Create Your Organization

```bash
task admin:grant -- <your-email-or-user-id>
```

Then create your organization:

```bash
task org:create
```

This will list site admin users, let you pick an owner, and create the org.
