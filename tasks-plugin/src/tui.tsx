import { Plugin } from "@opencode/plugin/tui";
import { createSignal } from "solid-js";
import { exec } from "child_process";
import { promises as fs } from "fs";
import path from "path";
import { parseAnsi } from "./ansi";

async function getTaskList(dir: string): Promise<string> {
  try {
    return new Promise<string>((resolve) => {
      exec("task list --width 40", { cwd: dir }, (error, stdout, stderr) => {
        if (error || stderr) {
          resolve("");
        } else {
          resolve(stdout.trim());
        }
      });
    });
  } catch {
    return "";
  }
}

// Convert a color name to an ANSI color code
// Hex colors pass through as-is for OpenTUI to render
function colorToCode(name: string): string {
  // Hex colors (#rrggbb) pass through unchanged
  if (name.startsWith("#")) {
    return name;
  }
  const map: Record<string, string> = {
    black: "black",
    red: "red",
    green: "green",
    yellow: "yellow",
    blue: "blue",
    magenta: "magenta",
    cyan: "cyan",
    white: "white",
  };
  return map[name] ?? "white";
}

// Build an OpenTUI style object from a parsed ANSI style
function toOpenTuiStyle(style?: { fg?: string; bg?: string; bold?: boolean; underline?: boolean; italic?: boolean; dim?: boolean }) {
  if (!style) return undefined;
  const result: any = {};
  if (style.fg) result.fg = colorToCode(style.fg);
  if (style.bg) result.bg = colorToCode(style.bg);
  if (style.bold) result.bold = true;
  if (style.underline) result.underline = true;
  if (style.italic) result.italic = true;
  if (style.dim) result.dim = true;
  return Object.keys(result).length > 0 ? result : undefined;
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

    let [taskListOutput, setTaskListOutput] = createSignal<string | null>(null);
    let refreshing = false;
    let lastDir: string | null = null;
    let foundDir: string | null = null;

    const refresh = async () => {
      if (refreshing) return;
      refreshing = true;
      try {
        const currentDir = ctx.location?.directory ?? process.cwd();
        // Re-detect if we've navigated to a different project
        if (currentDir !== lastDir) {
          lastDir = currentDir;
          foundDir = await findTaskDir(currentDir);
        }
        if (foundDir) {
          const raw = await getTaskList(foundDir);
          if (raw) {
            setTaskListOutput(raw);
          } else {
            setTaskListOutput(null);
          }
        }
      } catch (err) {
        setTaskListOutput(null);
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
      render: () => {
        const output = taskListOutput();
        if (output === null) {
          return null;
        }

        // Parse ANSI to segments, group by line
        const segments = parseAnsi(output);
        const lines: any[][] = [];
        let currentLine: any[] = [];
        
        for (const seg of segments) {
          if (seg.text.includes('\n')) {
            const parts = seg.text.split('\n');
            for (let i = 0; i < parts.length; i++) {
              if (i > 0 && currentLine.length > 0) {
                lines.push(currentLine);
                currentLine = [];
              }
              if (parts[i].length === 0) {
                lines.push([]);
              } else {
                currentLine.push({ text: parts[i], style: seg.style });
              }
            }
          } else {
            currentLine.push(seg);
          }
        }
        if (currentLine.length > 0) {
          lines.push(currentLine);
        }
        
        return (
          <box>
            {lines.map((lineSegments) => (
              <text>
                {lineSegments.map((seg) => {
                  const style = toOpenTuiStyle(seg.style);
                  if (style) {
                    return <span style={style}>{seg.text}</span>;
                  }
                  return seg.text;
                })}
              </text>
            ))}
          </box>
        );
      },
    });
  },
});
