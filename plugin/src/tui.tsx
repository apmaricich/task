import { Plugin } from "@opencode/plugin/tui";
import { Show } from "solid-js";
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

export default Plugin.define({
  id: "task-manager.tui",
  setup(ctx) {
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
          taskListOutput = await getTaskList(foundDir);
        }
      } catch (err) {
        taskListOutput = null;
      } finally {
        refreshing = false;
      }
    };

    // Initial refresh
    refresh();

    // Periodic refresh (every 30 seconds)
    const interval = setInterval(refresh, 30000);

    return ctx.ui.slot({
      append: "sidebar.content",
      render: () => (
        <Show when={taskListOutput !== null}>
          <box padding={2}>
            <text bold={true} fg="blue">
              Tasks
            </text>
            <text fg="gray" wrap={true}>
              {taskListOutput}
            </text>
          </box>
        </Show>
      ),
    });
  },
});