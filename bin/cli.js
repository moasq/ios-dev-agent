#!/usr/bin/env node

const { execSync, spawnSync } = require("child_process");
const path = require("path");
const fs = require("fs");

const PACKAGE_DIR = path.resolve(__dirname, "..");
const TARGET_DIR = process.cwd();
const args = process.argv.slice(2);

// Parse --tool flag
let tool = "auto";
const toolIdx = args.indexOf("--tool");
if (toolIdx !== -1 && args[toolIdx + 1]) {
  tool = args[toolIdx + 1];
}
if (args[0] && !args[0].startsWith("-")) {
  tool = args[0];
}

// Pass through to install.sh
const installScript = path.join(PACKAGE_DIR, "install.sh");
const env = { ...process.env, TARGET_DIR };
const result = spawnSync("bash", [installScript, "--tool", tool], {
  env,
  stdio: "inherit",
  cwd: PACKAGE_DIR,
});

process.exit(result.status || 0);
