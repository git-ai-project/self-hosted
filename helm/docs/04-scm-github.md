# SCM Setup: GitHub (Optional)

Use this if you want GitHub support. You can skip GitHub and use GitLab/Bitbucket only.

## Required URLs

If `global.webBaseUrl=https://gitai.example.com`:

- OAuth callback URL: `https://gitai.example.com/api/auth/callback/github`
- Install callback URL: `https://gitai.example.com/api/github/install/callback`
- Webhook URL: `https://gitai.example.com/worker/scm-webhook/<github-slug>`

Use the default slug `github` unless you run multiple GitHub instances.

## Create GitHub App (Step by Step)

1. Open [GitHub App creation](https://github.com/settings/apps/new).
2. Set **GitHub App name** (example: `git-ai-self-hosted`).
3. Set **Homepage URL** to `https://gitai.example.com`.
4. Set **Callback URL** to `https://gitai.example.com/api/auth/callback/github`.
5. Enable **Active** webhook.
6. Set **Webhook URL** to `https://gitai.example.com/worker/scm-webhook/github` (or your custom slug if you run multiple GitHub instances).
7. Set **Webhook secret** and keep it for the wizard.
8. Create the app.

## GitHub App Permissions (recommended baseline)

- Repository permissions:
  - Contents: Read & write
  - Pull requests: Read & write
  - Commit statuses: Read & write
  - Metadata: Read-only

## Subscribe to Events

- `push`
- `pull_request`
- `installation`
- `installation_repositories`
- `repository`

## Generate and Collect Credentials

1. In your app settings, copy **App ID**.
2. In **General**, copy **Client ID** and generate/copy **Client secret**.
3. In **Private keys**, click **Generate a private key** and download the `.pem` file.
4. Keep your webhook secret from creation step.

You will provide all of these to the wizard:

- App ID
- Webhook secret
- OAuth client ID
- OAuth client secret
- Private key PEM file path on disk

Run:

```bash
task scm:configure
```

## Post-Setup Verification

1. Open Git AI sign-in page and confirm **Continue with GitHub** is shown.
2. In Git AI org settings, open SCM settings and install/connect your GitHub app.
3. Confirm webhook deliveries succeed in GitHub app webhook logs.
