import { defineConfig } from "vite";
import { resolve, join } from "path";
import RubyPlugin, { projectRoot } from "vite-plugin-ruby";
import legacy from "@vitejs/plugin-legacy";

export default defineConfig({
  build: {
    emptyOutDir: true,
    targets: ["chrome65", "baseline-widely-available"],
  },
  css: {
    preprocessorOptions: {
      scss: {
        quietDeps: true,
        silenceDeprecations: ["import", "color-functions", "global-builtin"],
        verbose: false,
      },
    },
  },
  plugins: [RubyPlugin(), legacy({ targets: ["defaults"] })],
  resolve: {
    alias: {
      "@": resolve(join(projectRoot, "app/frontend")),
      "@images": resolve(join(projectRoot, "app/frontend/images")),
    },
  },
  test: {
    autoBuild: false,
    globals: true,
    environment: "jsdom",
    coverage: {
      provider: "v8",
      reporter: ["lcov", "text"],
    },
  },
});
