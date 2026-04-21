#!/usr/bin/env node
import { execSync } from "node:child_process";
import { randomBytes } from "node:crypto";
import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";

// --- KSUID generation (ported from npm `ksuid` package) ---

const BASE62_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const KSUID_EPOCH_MS = 14e11;
const KSUID_PAYLOAD_BYTES = 16;
const KSUID_STRING_LENGTH = 27;

function baseConvert(src, fromBase, toBase, fixedLength) {
  const result = new Array(fixedLength).fill(0);
  let offset = fixedLength;
  let arr = Array.from(src);

  while (arr.length > 0) {
    const quotients = [];
    let remainder = 0;
    for (const digit of arr) {
      const acc = digit + remainder * fromBase;
      const q = Math.floor(acc / toBase);
      remainder = acc % toBase;
      if (quotients.length > 0 || q > 0) {
        quotients.push(q);
      }
    }
    result[--offset] = remainder;
    arr = quotients;
  }

  return result;
}

function generateKSUID(prefix) {
  const timestamp = Math.floor((Date.now() - KSUID_EPOCH_MS) / 1e3);
  const tsBuffer = Buffer.allocUnsafe(4);
  tsBuffer.writeUInt32BE(timestamp, 0);
  const payload = randomBytes(KSUID_PAYLOAD_BYTES);
  const raw = Buffer.concat([tsBuffer, payload]);

  const encoded = baseConvert(raw, 256, 62, KSUID_STRING_LENGTH)
    .map((v) => BASE62_CHARS[v])
    .join("");

  return `${prefix}_${encoded}`;
}

// --- Docker Compose DB access ---

const ROOT_DIR = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const envPath = resolve(ROOT_DIR, ".env");

function parseEnvFile(filePath) {
  const out = {};
  let content;
  try {
    content = readFileSync(filePath, "utf8");
  } catch {
    return out;
  }
  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const idx = trimmed.indexOf("=");
    if (idx === -1) continue;
    const key = trimmed.slice(0, idx).trim();
    let value = trimmed.slice(idx + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    out[key] = value;
  }
  return out;
}

const env = parseEnvFile(envPath);
const POSTGRES_USER = env.POSTGRES_USER || "postgres";
const POSTGRES_DB = env.POSTGRES_DB || "postgres";

function runSQL(sql) {
  const escaped = sql.replace(/'/g, "'\\''");
  return execSync(
    `docker compose exec -T db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -A -c '${escaped}'`,
    { encoding: "utf8", cwd: ROOT_DIR }
  ).trim();
}

// --- Slug generation ---

function slugify(name) {
  let slug = name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 39);
  return slug || "org";
}

// --- Main ---

async function main() {
  console.log("");
  console.log("=== Create Organization ===");
  console.log("");
  console.log("The org owner must be a site admin. Sign in, then run 'task admin:grant' first.");
  console.log("");

  // List admin users only
  const usersRaw = runSQL("SELECT id, name, email FROM \"user\" WHERE role = 'admin' ORDER BY created_at");
  if (!usersRaw) {
    console.error("No admin users found. Sign in to the application and run 'task admin:grant -- <email>' first.");
    process.exit(1);
  }

  const users = usersRaw.split("\n").map((line) => {
    const [id, name, email] = line.split("|");
    return { id, name, email };
  });

  console.log("Site admins:");
  console.log("");
  users.forEach((u, i) => {
    console.log(`  ${i + 1}) ${u.name} <${u.email}>`);
  });
  console.log("");

  const rl = readline.createInterface({ input, output });

  let userIdx;
  while (true) {
    const answer = await rl.question(`Select the admin who will own this org (1-${users.length}): `);
    userIdx = parseInt(answer, 10) - 1;
    if (userIdx >= 0 && userIdx < users.length) break;
    console.log("Invalid selection. Please enter a number from the list.");
  }
  const owner = users[userIdx];

  let orgName;
  while (true) {
    orgName = (await rl.question("Enter organization name: ")).trim();
    if (orgName) break;
    console.log("Organization name is required.");
  }

  rl.close();

  // Generate slug and check uniqueness
  let slug = slugify(orgName);
  const existingSlugs = runSQL(`SELECT slug FROM organization WHERE slug LIKE '${slug}%'`);
  if (existingSlugs && existingSlugs.split("\n").includes(slug)) {
    const suffix = Math.floor(Math.random() * 10000);
    slug = `${slug.slice(0, 34)}-${suffix}`;
  }

  // Generate IDs
  const orgId = generateKSUID("org");
  const memberId = generateKSUID("member");
  const now = new Date().toISOString();

  // Insert in transaction (SQL-escape org name for apostrophes)
  const safeName = orgName.replace(/'/g, "''");
  const insertSQL = `BEGIN; INSERT INTO organization (id, name, slug, created_at, is_personal_org, is_self_hosted_org, onboarding_complete, disable_intermediate_pr_analysis, prompt_visibility) VALUES ('${orgId}', '${safeName}', '${slug}', '${now}', false, true, true, false, 'admins_only'); INSERT INTO member (id, organization_id, user_id, role, created_at) VALUES ('${memberId}', '${orgId}', '${owner.id}', 'owner', '${now}'); COMMIT;`;
  runSQL(insertSQL);

  console.log("");
  console.log(`Organization '${orgName}' created successfully.`);
  console.log(`  ID:    ${orgId}`);
  console.log(`  Slug:  ${slug}`);
  console.log(`  Owner: ${owner.name} <${owner.email}>`);
  console.log("");
}

main().catch((err) => {
  console.error("Error:", err.message);
  process.exit(1);
});
