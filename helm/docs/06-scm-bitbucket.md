# SCM Setup: Bitbucket (Optional)

## Required URL

If `global.webBaseUrl=https://gitai.example.com`:

- OAuth callback URL: `https://gitai.example.com/api/auth/oauth2/callback/bitbucket`

Webhooks for connected workspaces are created by Git AI automatically using:

- `https://gitai.example.com/worker/scm-webhook/<bitbucket-slug>?connection_token=<token>`

Use the default slug `bitbucket` unless you run multiple Bitbucket instances.

## Create Bitbucket OAuth Consumer (Step by Step)

1. Open Bitbucket workspace settings.
2. Go to **OAuth consumers** and create a **Private consumer**.
3. Callback URL: `https://gitai.example.com/api/auth/oauth2/callback/bitbucket`.
4. Enable scopes:
   - `account`
   - `repository`
   - `webhook`
   - `email`
5. Save consumer.
6. Copy **Key** (client id) and **Secret** (client secret).

## Credentials Needed by Wizard

- Domain (default `bitbucket.org`)
- App slug (default `bitbucket`; change it only if you run multiple Bitbucket instances)
- App identifier (default `bitbucket`)
- Webhook secret
- OAuth client ID
- OAuth client secret

Run:

```bash
task scm:configure
```

## Post-Setup Verification

1. Open Git AI sign-in page and confirm **Continue with Bitbucket** is shown.
2. In Git AI org SCM settings, connect your Bitbucket account.
3. Connect a workspace and confirm webhook creation in Bitbucket workspace/repo settings.
