import { Plugin } from "@opencode/plugin/tui";
import { promises as fs } from "fs";
import path from "path";
import { exec } from "child_process";
import { createSignal } from "solid-js";
import { parseAnsi } from "./ansi";

/**
 * Traverse up the filesystem looking for a tasks.json file.
 * Returns the directory containing tasks.json, or null if not found.
 */
export async function findTaskDir(currentPath: string): Promise<string | null> {
  let dir = currentPath;

  while (true) {
    const candidate = path.join(dir, "tasks.json");

    try {
      await fs.access(candidate);
      return dir;
    } catch {
      // tasks.json not found in this directory, go up
    }

    const parent = path.dirname(dir);
    if (parent === dir) {
      // Reached filesystem root
      return null;
    }
    dir = parent;
  }
}

/**
 * Execute `task stats` in the given directory.
 * Returns the stdout on success, or an empty string on error.
 */
async function getTaskStats(dir: string): Promise<string> {
  return new Promise((resolve) => {
    exec("task stats --width 40", { cwd: dir }, (error, stdout, stderr) => {
      if (error || stderr) {
        resolve("");
      } else {
        resolve(stdout.trim());
      }
    });
  });
}

// Convert a color name to an ANSI color code
// Hex colors pass through as-is for OpenTUI to render
function colorToCode(name: string): string {
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
  id: "task-stats.tui",
  setup(ctx) {
    let refreshing = false;
    let lastDir: string | null = null;
    let foundDir: string | null = null;
    const [stats, setStats] = createSignal<string>("");

    // Refresh stats from the current task directory
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
          const result = await getTaskStats(foundDir);
          setStats(result);
        }
      } catch {
        setStats("");
      } finally {
        refreshing = false;
      }
    };

    // Initial refresh
    refresh();

    // Periodic refresh every 30 seconds
    const interval = setInterval(refresh, 30_000);

    return ctx.ui.slot({
      append: "sidebar.content",
      render: () => {
        const statsText = stats();
        if (!statsText) {
          return null;
        }

        // Parse ANSI to segments, group by line
        const segments = parseAnsi(statsText);
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
              if (parts[i].length > 0) {
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