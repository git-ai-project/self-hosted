# SCM Setup: GitLab (Optional)

## Required URL

If `global.webBaseUrl=https://gitai.example.com`:

- OAuth callback URL: `https://gitai.example.com/api/auth/callback/gitlab`

Webhooks for connected groups are created by Git AI automatically using:

- `https://gitai.example.com/worker/scm-webhook/<gitlab-slug>?connection_token=<token>`

Use the default slug `gitlab` unless you run multiple GitLab instances.

## Create GitLab OAuth App (Step by Step)

1. Open GitLab and go to **User Settings -> Applications**.
2. Name: choose your own (example `git-ai-self-hosted`).
3. Redirect URI: `https://gitai.example.com/api/auth/callback/gitlab`.
4. Select scopes:
   - `api`
   - `read_user`
5. Save application.
6. Copy **Application ID** (client id) and **Secret** (client secret).

## Credentials Needed by Wizard

- Domain (default `gitlab.com`)
- App slug (default `gitlab`; change it only if you run multiple GitLab instances)
- App identifier (default `gitlab`)
- Webhook secret
- OAuth client ID
- OAuth client secret

Run:

```bash
task scm:configure
```

## Post-Setup Verification

1. Open Git AI sign-in page and confirm **Continue with GitLab** is shown.
2. In Git AI org SCM settings, connect your GitLab account.
3. Connect a group and confirm Git AI creates webhook entries in GitLab group webhook settings.
