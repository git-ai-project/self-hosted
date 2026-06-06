# SCM Setup: Azure DevOps (Optional)

## Required URL

If `WEB_BASE_URL=https://gitai.example.com`:

- OAuth callback URL: `https://gitai.example.com/api/auth/callback/azure-devops`

Webhooks for connected projects are created by Git AI automatically using:

- `https://gitai.example.com/worker/scm-webhook/<azure-devops-slug>?connection_token=<token>`

Use the default slug `azure-devops` unless you run multiple Azure DevOps instances.

## Create Azure DevOps OAuth App

Create an Azure DevOps OAuth application for your organization and configure its
callback URL as `https://gitai.example.com/api/auth/callback/azure-devops`.

Grant scopes that allow Git AI to read user identity, read repositories and pull
requests, create/update pull request comments, create service hooks, and update
commit or PR statuses. Keep the generated client ID and client secret for the
wizard.

## Credentials Needed by Wizard

- Domain (default `dev.azure.com`)
- App slug (default `azure-devops`; change it only if you run multiple Azure DevOps instances)
- App identifier (default `azure-devops`)
- Webhook secret
- OAuth client ID
- OAuth client secret

Run:

```bash
task scm:configure
```

## Post-Setup Verification

1. Open Git AI sign-in page and confirm **Continue with Azure DevOps** is shown.
2. In Git AI org SCM settings, connect your Azure DevOps account.
3. Connect an organization/project and confirm webhook creation in Azure DevOps service hooks.
