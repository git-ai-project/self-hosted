# SCM Setup: Bitbucket Data Center (Optional)

This setup is separate from Bitbucket Cloud. Git AI requires Bitbucket Data Center 8.8 or later because it creates a project-level webhook for each connected project.

## Prerequisites

- Git AI can reach the Bitbucket Data Center base URL.
- Bitbucket Data Center can reach `global.webBaseUrl`.
- Both services use HTTPS with certificates trusted by the other service.
- You can create an incoming application link in Bitbucket.
- A dedicated Bitbucket service account is a project administrator for every project that Git AI will connect.

If Bitbucket is installed under a context path, include it in the base URL, for example `https://bitbucket.example.com/bitbucket`.

## Required URLs

If `global.webBaseUrl=https://gitai.example.com` and you use the default slug:

- OAuth callback URL: `https://gitai.example.com/api/auth/oauth2/callback/bitbucket-datacenter`
- Project webhook base: `https://gitai.example.com/worker/scm-webhook/bitbucket-datacenter?connection_token=<token>`

Git AI creates and signs project webhooks automatically. Use the default slug `bitbucket-datacenter` unless you configure multiple Bitbucket Data Center instances. The slug is part of both URLs, so the callback URL in Bitbucket must match it exactly.

## Create the OAuth Incoming Link

Follow [Atlassian's incoming-link guide](https://confluence.atlassian.com/bitbucketserver/configure-an-incoming-link-1108483657.html):

1. In Bitbucket, go to **Administration -> Applications -> Application links**.
2. Select **Create link -> External application -> Incoming**.
3. Set **Redirect URL** to `https://gitai.example.com/api/auth/oauth2/callback/bitbucket-datacenter`.
4. Under **Repositories**, select **Read**. Leave the other scopes unselected.
5. Save the link.
6. Copy the generated **Client ID** and **Client secret**.

The authorizing user can only expose projects that their Bitbucket account is allowed to view.

## Create the HTTP Access Token

Git AI uses a separate service-account token to clone repositories and manage project webhooks:

1. Sign in as the dedicated service account.
2. Go to **Profile picture -> Manage account -> HTTP access tokens**.
3. Create a token dedicated to Git AI.
4. Grant **Project admin** and **Repository admin** permissions.
5. Copy the token when it is shown.

The service account must be a project administrator for each connected project. See Atlassian's [HTTP access token guide](https://confluence.atlassian.com/bitbucketserver/http-access-tokens-939515499.html) for token creation and expiry options.

## Credentials Needed by Wizard

- Bitbucket Data Center base URL, including any context path
- App slug (default `bitbucket-datacenter`)
- App identifier (default `bitbucket-datacenter`)
- Personal HTTP access token
- OAuth client ID
- OAuth client secret

Run:

```bash
task scm:configure
```

The wizard derives the `domain` from the base URL and supplies the app-level webhook placeholder. Each project connection receives its own generated webhook secret and path token.

## Post-Setup Verification

1. Open the Git AI sign-in page and confirm **Continue with Bitbucket Data Center** is shown.
2. Sign in through Bitbucket and approve repository read access.
3. In Git AI org SCM settings, connect a Bitbucket Data Center project.
4. In the Bitbucket project's webhook settings, confirm an active **Git AI** webhook was created.
5. Open or update a pull request and confirm its webhook delivery succeeds.

If project connection fails, verify the service-account token is not expired and has project-admin access. If OAuth or webhook delivery fails, verify both base URLs, the context path, DNS, TLS trust, and network reachability in both directions.

## Local Evaluation

For non-production validation, use Atlassian's official [`atlassian/bitbucket` image](https://hub.docker.com/r/atlassian/bitbucket) with a PostgreSQL database and an [Atlassian timebomb license](https://developer.atlassian.com/platform/marketplace/timebomb-licenses-for-testing-server-apps/). Timebomb licenses and HTTP-only OAuth overrides are for testing only; production integrations should use a normal Data Center license and HTTPS.
