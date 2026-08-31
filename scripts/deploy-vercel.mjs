import { execFileSync, spawnSync } from "node:child_process";

const projects = {
  "piano-tool": {
    directory: "apps/piano-tool",
    branch: "piano-tool",
  },
  "wesnest-search": {
    directory: "apps/wesnest-search",
    branch: "wesnest-search",
  },
  "comment-lens": {
    directory: "apps/comment-lens",
    branch: "comment-lens",
  },
};

const usage = "Usage: pnpm deploy:vercel <piano-tool|wesnest-search|comment-lens> [vercel options]";
const [projectName, ...vercelArgs] = process.argv.slice(2);

if (projectName === "--help" || projectName === "-h") {
  console.log(usage);
  process.exit(0);
}

if (!projectName || !projects[projectName]) {
  console.error(usage);
  process.exit(2);
}

if (vercelArgs.some((arg) => arg === "--cwd" || arg.startsWith("--cwd="))) {
  console.error("Do not override the project directory selected by this wrapper.");
  process.exit(2);
}

let repoRoot;
let branch;

try {
  repoRoot = execFileSync("git", ["rev-parse", "--show-toplevel"], {
    encoding: "utf8",
  }).trim();
  branch = execFileSync("git", ["branch", "--show-current"], {
    cwd: repoRoot,
    encoding: "utf8",
  }).trim();
} catch {
  console.error("This command must run inside the code-wes-projects Git repository.");
  process.exit(1);
}

const project = projects[projectName];

if (branch !== project.branch) {
  console.error(
    `Refusing to deploy ${projectName} from ${branch || "a detached HEAD"}. ` +
      `Deploy it only from ${project.branch}.`,
  );
  process.exit(1);
}

const forwardedArgs = vercelArgs.filter((arg) => arg !== "--prod");
const result = spawnSync(
  "vercel",
  ["--cwd", project.directory, "deploy", "--prod", ...forwardedArgs],
  {
    cwd: repoRoot,
    stdio: "inherit",
  },
);

if (result.error) {
  console.error(`Unable to run Vercel CLI: ${result.error.message}`);
  process.exit(1);
}

process.exit(result.status ?? 1);
