# Prerequisites

Install:

- Docker + Docker Compose plugin
- `task` CLI ([go-task](https://taskfile.dev/))
- Node.js 22+ (for the SCM wizard script)
- `openssl` CLI (used by `task init` to generate secrets)

You also need:

- A valid Git AI enterprise `LICENSE_KEY`
- At least one SCM app configured (GitHub, GitLab, and/or Bitbucket)
- For most installs, one app per provider with the default slug (`github`, `gitlab`, `bitbucket`)

## Network Requirements

- Pull access to your configured `WEB_IMAGE` registry
- Outbound access to configured SCM providers
- Inbound access from SCM webhook delivery to your `WEB_BASE_URL`
