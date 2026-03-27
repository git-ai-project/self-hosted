# Admin Bootstrap and Onboarding Gate

After first sign-in, your account is usually not `admin` yet.

## 1) Promote Yourself to Admin

```bash
task admin:grant -- <your-email-or-user-id>
```

`task admin:grant` and `task admin:psql` target the application database `gitai` by default.
If you changed `postgresql.auth.database`, run them with `APP_DB_NAME=<your-db>`.

Equivalent SQL (via `task admin:psql`):

```sql
UPDATE "user" SET role='admin' WHERE email='<you@example.com>' OR id='<user_id>';
```

## 2) Remove Book Demo Gating for Your Org

1. Open `/admin`
2. Open **Organizations**
3. Find your org
4. Open the row action menu (three dots)
5. Click **Mark Onboarding Complete**

That action sets org onboarding complete and removes the book demo / booking screen.
