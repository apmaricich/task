// Simple test to verify the plugin can execute task list

import { exec } from "child_process";
import { promises as fs } from "fs";

async function getTaskList(): Promise<string | null> {
  try {
    return new Promise<string>((resolve, reject) => {
      exec("task list", (error, stdout, stderr) => {
        if (error || stderr) {
          resolve(null);
        } else {
          resolve(stdout.trim());
        }
      });
    });
  } catch {
    return null;
  }
}

async function findTaskDir(path: string): Promise<string | null> {
  try {
    const entries = await fs.readdir(path);
    if (entries.includes("tasks.json")) {
      return path;
    }
    const parent = path + "/..";
    if (parent !== "/" && parent !== path) {
      return findTaskDir(parent);
    }
  } catch {
    // Not a directory, or error
  }
  return null;
}

async function main() {
  const taskDir = await findTaskDir(".");
  console.log("Task dir:", taskDir);
  
  if (taskDir) {
    const list = await getTaskList();
    console.log("Task list:");
    console.log(list);
  }
}

main();