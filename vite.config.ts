import { defineConfig } from "vite";
import { resolve, join } from "path";

import RubyPlugin, { projectRoot } from "vite-plugin-ruby";
import { createVuePlugin } from "vite-plugin-vue2";
import legacy from "@vitejs/plugin-legacy";

export default defineConfig({
  plugins: [RubyPlugin(), createVuePlugin(), legacy({ targets: ["defaults"] })],
  resolve: {
    alias: {
      "@": resolve(join(projectRoot, "app/javascript")),
      "@sharedComponents": resolve(join(projectRoot, "app/javascript/shared/components")),
    },
  },
});