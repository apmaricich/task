import { Plugin } from "@opencode/plugin";

export default Plugin.define({
  id: "task-manager",
  setup(ctx) {
    // Log to stderr to ensure it appears in the OpenCode log
    process.stderr.write("[task-manager] Server plugin loaded\n");
  },
});