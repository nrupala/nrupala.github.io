#!/usr/bin/env node
// bump-version.mjs - STANDARD app versioning (author-time bump).
import { readFileSync, writeFileSync, existsSync } from "node:fs";

const ver = process.argv[2];
if (!ver || !/^\d+\.\d+\.\d+$/.test(ver)) {
  console.error("usage: node scripts/bump-version.mjs <X.Y.Z>");
  process.exit(1);
}
const log = [];

// 1) VERSION - the single source of truth (non-JS repo)
if (existsSync("VERSION")) {
  const prev = readFileSync("VERSION", "utf8").trim();
  writeFileSync("VERSION", ver + "\n");
  log.push(`VERSION  ${prev} -> ${ver}`);
}

// 2) on-page <meta name="app-version"> marker (web app)
const meta = "index.html";
if (existsSync(meta)) {
  const src = readFileSync(meta, "utf8");
  const out = src.replace(/(<meta name="app-version" content=")\d+\.\d+\.\d+(")/g, `$1${ver}$2`);
  writeFileSync(meta, out);
  log.push(`index.html app-version meta  ${out !== src ? "updated" : "NO MATCH"}`);
}

// 6) CHANGELOG heading - promote Unreleased into a dated release section
const cl = "CHANGELOG.md";
if (existsSync(cl)) {
  const today = new Date().toISOString().slice(0, 10);
  const src = readFileSync(cl, "utf8");
  if (src.includes("## [Unreleased]")) {
    const out = src.replace("## [Unreleased]", `## [Unreleased]\n\n## [${ver}] - ${today}`);
    writeFileSync(cl, out);
    log.push(`CHANGELOG.md  new heading [${ver}] - ${today}`);
  }
}


console.log("bumped to " + ver + ":");
for (const line of log) console.log("  " + line);
console.log(`next: git commit -am "chore: v${ver}" && git tag v${ver} && git push --follow-tags`);
