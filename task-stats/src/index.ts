import { Plugin } from "@opencode/plugin";

export default Plugin.define({
  id: "task-stats",
  setup(ctx) {
    // Log to stderr to ensure it appears in the OpenCode log
    process.stderr.write("[task-stats] Server plugin loaded\n");
  },
});
