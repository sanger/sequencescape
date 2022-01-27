import { defineConfig } from "vite";
import { resolve, join } from "path";

import RubyPlugin, { projectRoot } from "vite-plugin-ruby";
import { createVuePlugin } from "vite-plugin-vue2";

export default defineConfig({
  plugins: [RubyPlugin(), createVuePlugin()],
  resolve: {
    alias: {
      "@": resolve(join(projectRoot, "app/javascript")),
      "@sharedComponents": resolve(join(projectRoot, "app/javascript/shared/components")),
    },
  },
});
