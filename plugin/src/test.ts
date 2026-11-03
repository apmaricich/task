// Simple test to verify the plugin can execute task list

import { exec } from "child_process";
import { promises as fs } from "fs";
import path from "path";

// Strip ANSI escape codes from the output
function stripAnsi(input: string): string {
  return input.replace(/\u001b\[[0-9;]*[mGK]/g, "");
}

async function getTaskList(dir: string): Promise<string | null> {
  try {
    return new Promise<string>((resolve) => {
      exec("task list", { cwd: dir }, (error, stdout, stderr) => {
        if (error || stderr) {
          resolve(null);
        } else {
          resolve(stripAnsi(stdout.trim()));
        }
      });
    });
  } catch {
    return null;
  }
}

async function findTaskDir(currentPath: string): Promise<string | null> {
  let searchPath = currentPath;
  while (searchPath !== "/") {
    try {
      const entries = await fs.readdir(searchPath);
      if (entries.includes("tasks.json")) {
        return searchPath;
      }
    } catch {
      // Not a directory, or permission error - keep searching up
    }
    searchPath = path.dirname(searchPath);
  }
  return null;
}

async function main() {
  const taskDir = await findTaskDir(".");
  console.log("Task dir:", taskDir);
  
  if (taskDir) {
    const list = await getTaskList(taskDir);
    console.log("Task list:");
    console.log(list);
  }
}

main();