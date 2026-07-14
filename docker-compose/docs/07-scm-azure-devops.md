# SCM Setup: Azure DevOps (Optional)

Azure DevOps uses Microsoft Entra ID (formerly Azure AD) for OAuth. Do not use the deprecated Azure DevOps OAuth registration flow.

## Required URL

If `WEB_BASE_URL=https://gitai.example.com`:

- OAuth callback URL: `https://gitai.example.com/api/auth/oauth2/callback/azure-devops`

Service hooks for connected organizations are created by Git AI automatically using:

- `https://gitai.example.com/worker/scm-webhook/<azure-devops-slug>?connection_token=<token>`

Use the default slug `azure-devops` unless you run multiple Azure DevOps app registrations.

## Create Microsoft Entra App (Step by Step)

1. Open the [Azure Portal](https://portal.azure.com) and go to **Microsoft Entra ID -> App registrations -> New registration**.
2. Set **Name** (example: `git-ai-self-hosted`).
3. Set **Supported account types**:
   - Choose **Accounts in any organizational directory** for a multi-tenant app.
   - Choose your organization only for a single-tenant app.
4. Add a **Web** redirect URI: `https://gitai.example.com/api/auth/oauth2/callback/azure-devops`.
5. Open **API permissions -> Add a permission -> Azure DevOps -> Delegated permissions** and select:
   - `vso.code_write` — Code (read and write), including service hooks.
   - `vso.code_status` — Code status.
   - `vso.identity` — Identity (read).
   - `vso.graph` — Graph (read).
   - `vso.profile` — User profile (read).
   - `vso.project` — Project and team (read).
   - `vso.work` — Work items (read).
6. Grant tenant admin consent if your Microsoft Entra policies require it.
7. Open **Certificates & secrets -> Client secrets -> New client secret**.
8. Copy the secret value when it is shown.

## Credentials Needed by Wizard

- Domain (default `dev.azure.com`)
- App slug (default `azure-devops`; change it only if you use multiple app registrations)
- App identifier (default `azure-devops`)
- Microsoft Entra Application (client) ID
- Microsoft Entra client secret value
- Tenant ID:
  - `common` for a multi-tenant app
  - Your Microsoft Entra tenant ID for a single-tenant app
- Optional Azure DevOps personal access token (PAT) for app-level operations when no connected-user OAuth token is available

Git AI creates a unique secret for each Azure DevOps service-hook connection and sends it in the `X-Azure-DevOps-Secret` header, so the wizard supplies the required app-level webhook placeholder automatically.

Run:

```bash
task scm:configure
```

## Post-Setup Verification

1. Open the Git AI sign-in page and confirm **Continue with Azure DevOps** is shown.
2. In Git AI org SCM settings, click **Connect Azure DevOps account**.
3. Select or enter an Azure DevOps organization where the connected user is a member.
4. Confirm Git AI creates service-hook subscriptions for pull request creation, pull request updates, and pushes.
5. Confirm service-hook deliveries succeed in **Azure DevOps organization settings -> Service hooks**.
