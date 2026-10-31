import { Plugin } from "@opencode/plugin/tui";
import { Show } from "solid-js";
import { exec } from "child_process";
import { promises as fs } from "fs";
import path from "path";

async function getTaskList(dir: string): Promise<string | null> {
  try {
    return new Promise<string>((resolve) => {
      exec("task list", { cwd: dir }, (error, stdout, stderr) => {
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

export default Plugin.define({
  id: "task-manager.tui",
  setup(ctx) {
    // Explicitly log to stderr to ensure it appears in the OpenCode log
    process.stderr.write("[task-manager] Plugin setup starting\n");
    
    // Find the task-manager project location by traversing up the filesystem
    // looking for tasks.json. This ensures the correct task list is shown.
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

    let taskListOutput: string | null = null;
    let refreshing = false;
    let foundDir: string | null = null;

    const refresh = async () => {
      if (refreshing) return;
      refreshing = true;
      try {
        const currentDir = ctx.location?.directory ?? process.cwd();
        if (!foundDir) {
          foundDir = await findTaskDir(currentDir);
        }
        if (foundDir) {
          console.log("[task-manager] Found task dir:", foundDir);
          // Test the shell first
          const testResult = await getTaskList(foundDir);
          if (!testResult) {
            // Try using the full path to the task binary
            console.log("[task-manager] Shell test failed, trying full path");
          }
          taskListOutput = testResult;
          console.log("[task-manager] Task list output:", taskListOutput);
        }
      } catch (err) {
        console.log("[task-manager] Refresh error:", err);
        taskListOutput = null;
      } finally {
        refreshing = false;
      }
    };

    // Initial refresh
    refresh();

    // Refresh on session changes
    ctx.data.on("session.list.updated", refresh);
    ctx.data.on("session.created", refresh);

    return ctx.ui.slot({
      append: "sidebar.content",
      render: () => (
        <Show when={taskListOutput !== null}>
          <box padding={2}>
            <text bold={true} fg="blue">
              Tasks
            </text>
            <text fg="gray" wrap={true}>
              {taskListOutput ?? "Loading..."}
            </text>
          </box>
        </Show>
      ),
    });
  },
});