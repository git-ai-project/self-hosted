#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";
import { fileURLToPath } from "node:url";

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const envPath = path.join(rootDir, ".env");
const configDir = path.join(rootDir, "config");
const generatedDir = path.join(rootDir, "generated");
const generatedConfigPath = path.join(configDir, "scm-apps.generated.json");
const generatedEnvPath = path.join(generatedDir, "scm.env");

function parseEnvFile(filePath) {
  if (!fs.existsSync(filePath)) {
    return {};
  }
  const out = {};
  const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const idx = trimmed.indexOf("=");
    if (idx === -1) continue;
    const key = trimmed.slice(0, idx).trim();
    let value = trimmed.slice(idx + 1).trim();
    if ((value.startsWith("\"") && value.endsWith("\"")) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    out[key] = value;
  }
  return out;
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function shellEscapeSingleQuoted(value) {
  return value.replace(/'/g, "'\\''");
}

async function askWithDefault(rl, prompt, defaultValue = "") {
  const suffix = defaultValue ? ` [${defaultValue}]` : "";
  const answer = (await rl.question(`${prompt}${suffix}: `)).trim();
  return answer || defaultValue;
}

async function askRequired(rl, prompt, defaultValue = "") {
  while (true) {
    const answer = await askWithDefault(rl, prompt, defaultValue);
    if (answer) return answer;
    console.log("This field is required.");
  }
}

async function askYesNo(rl, prompt, defaultValue) {
  const defaultText = defaultValue ? "Y/n" : "y/N";
  while (true) {
    const answer = (await rl.question(`${prompt} (${defaultText}): `)).trim().toLowerCase();
    if (!answer) return defaultValue;
    if (["y", "yes"].includes(answer)) return true;
    if (["n", "no"].includes(answer)) return false;
    console.log("Please answer yes or no.");
  }
}

function validateApps(apps) {
  if (!Array.isArray(apps) || apps.length === 0) {
    throw new Error("At least one SCM app is required.");
  }

  const required = ["provider", "domain", "slug", "app_id", "webhook_secret", "client_id", "client_secret"];
  const supportedProviders = new Set(["github", "gitlab", "bitbucket"]);
  const seenSlugs = new Set();
  apps.forEach((app, index) => {
    for (const key of required) {
      if (typeof app[key] !== "string" || app[key].trim() === "") {
        throw new Error(`SCM app #${index + 1} is missing required field '${key}'.`);
      }
    }

    const provider = app.provider.trim().toLowerCase();
    if (!supportedProviders.has(provider)) {
      throw new Error(
        `SCM app #${index + 1} has unsupported provider '${app.provider}'. Supported: github, gitlab, bitbucket.`
      );
    }

    const slug = app.slug.trim();
    if (seenSlugs.has(slug)) {
      throw new Error(`SCM app #${index + 1} duplicates slug '${slug}'. Slugs must be unique.`);
    }
    seenSlugs.add(slug);
  });
}

async function main() {
  ensureDir(configDir);
  ensureDir(generatedDir);

  const env = parseEnvFile(envPath);
  const baseUrl = env.WEB_BASE_URL || "http://localhost:3000";

  const rl = readline.createInterface({ input, output });
  try {
    console.log("Configure SCM apps for self-hosting");
    console.log(`Detected WEB_BASE_URL: ${baseUrl}`);
    console.log("Keep the default slug unless you run multiple instances of the same provider: github, gitlab, bitbucket.");
    console.log("");

    const enableGitHub = await askYesNo(rl, "Configure GitHub?", true);
    const enableGitLab = await askYesNo(rl, "Configure GitLab?", false);
    const enableBitbucket = await askYesNo(rl, "Configure Bitbucket?", false);

    if (!enableGitHub && !enableGitLab && !enableBitbucket) {
      console.error("At least one SCM is required. Re-run this command and configure at least one provider.");
      process.exit(1);
    }

    const apps = [];

    if (enableGitHub) {
      console.log("\nGitHub configuration");
      const domain = await askRequired(rl, "GitHub domain", "github.com");
      const slug = await askRequired(
        rl,
        "GitHub app slug (use 'github' unless you have multiple GitHub instances)",
        "github"
      );
      const appId = await askRequired(rl, "GitHub App ID");
      const webhookSecret = await askRequired(rl, "GitHub webhook secret");
      const clientId = await askRequired(rl, "GitHub OAuth client ID");
      const clientSecret = await askRequired(rl, "GitHub OAuth client secret");
      const privateKeyPath = await askRequired(rl, "Path to GitHub private key PEM file");

      const resolvedKeyPath = path.resolve(rootDir, privateKeyPath);
      if (!fs.existsSync(resolvedKeyPath)) {
        throw new Error(`GitHub private key file not found: ${resolvedKeyPath}`);
      }

      apps.push({
        provider: "github",
        domain,
        slug,
        app_id: appId,
        webhook_secret: webhookSecret,
        client_id: clientId,
        client_secret: clientSecret,
        private_key: fs.readFileSync(resolvedKeyPath, "utf8"),
      });
    }

    if (enableGitLab) {
      console.log("\nGitLab configuration");
      const domain = await askRequired(rl, "GitLab domain", "gitlab.com");
      const slug = await askRequired(
        rl,
        "GitLab app slug (use 'gitlab' unless you have multiple GitLab instances)",
        "gitlab"
      );
      const appId = await askRequired(rl, "GitLab app identifier", "gitlab");
      const webhookSecret = await askRequired(rl, "GitLab webhook secret");
      const clientId = await askRequired(rl, "GitLab OAuth client ID");
      const clientSecret = await askRequired(rl, "GitLab OAuth client secret");

      apps.push({
        provider: "gitlab",
        domain,
        slug,
        app_id: appId,
        webhook_secret: webhookSecret,
        client_id: clientId,
        client_secret: clientSecret,
      });
    }

    if (enableBitbucket) {
      console.log("\nBitbucket configuration");
      const domain = await askRequired(rl, "Bitbucket domain", "bitbucket.org");
      const slug = await askRequired(
        rl,
        "Bitbucket app slug (use 'bitbucket' unless you have multiple Bitbucket instances)",
        "bitbucket"
      );
      const appId = await askRequired(rl, "Bitbucket app identifier", "bitbucket");
      const webhookSecret = await askRequired(rl, "Bitbucket webhook secret");
      const clientId = await askRequired(rl, "Bitbucket OAuth client ID");
      const clientSecret = await askRequired(rl, "Bitbucket OAuth client secret");

      apps.push({
        provider: "bitbucket",
        domain,
        slug,
        app_id: appId,
        webhook_secret: webhookSecret,
        client_id: clientId,
        client_secret: clientSecret,
      });
    }

    validateApps(apps);

    fs.writeFileSync(generatedConfigPath, `${JSON.stringify(apps, null, 2)}\n`, "utf8");

    const compactJson = JSON.stringify(apps);
    fs.writeFileSync(
      generatedEnvPath,
      `SCM_APPS_CONFIG='${shellEscapeSingleQuoted(compactJson)}'\n`,
      "utf8"
    );

    console.log("\nGenerated files:");
    console.log(`- ${generatedConfigPath}`);
    console.log(`- ${generatedEnvPath}`);

    console.log("\nProvider setup URLs:");
    if (enableGitHub) {
      console.log(`- GitHub callback URL: ${baseUrl}/api/auth/callback/github`);
      console.log(`- GitHub setup URL: leave blank when "Request user authorization (OAuth) during installation" is enabled`);
      const githubSlug = apps.find((a) => a.provider === "github")?.slug;
      console.log(`- GitHub webhook URL: ${baseUrl}/worker/scm-webhook/${githubSlug}`);
    }
    if (enableGitLab) {
      const gitLabSlug = apps.find((a) => a.provider === "gitlab")?.slug;
      console.log(`- GitLab callback URL: ${baseUrl}/api/auth/callback/gitlab`);
      console.log(`- GitLab webhook base: ${baseUrl}/worker/scm-webhook/${gitLabSlug}?connection_token=<token>`);
    }
    if (enableBitbucket) {
      const bitbucketSlug = apps.find((a) => a.provider === "bitbucket")?.slug;
      console.log(`- Bitbucket callback URL: ${baseUrl}/api/auth/oauth2/callback/bitbucket`);
      console.log(`- Bitbucket webhook base: ${baseUrl}/worker/scm-webhook/${bitbucketSlug}?connection_token=<token>`);
    }

    console.log("\nDone. Next: task up");
  } finally {
    rl.close();
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
