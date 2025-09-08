import { defineConfig } from "vite";
import { resolve, join } from "path";
import RubyPlugin, { projectRoot } from "vite-plugin-ruby";
import { createVuePlugin } from "vite-plugin-vue2";
import legacy from "@vitejs/plugin-legacy";

export default defineConfig({
  build: {
    emptyOutDir: true,
    target: ["chrome65", "es2019"],
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
  plugins: [RubyPlugin(), createVuePlugin(), legacy({ targets: ["defaults"] })],
  resolve: {
    alias: {
      "@": resolve(join(projectRoot, "app/frontend")),
      "@sharedComponents": resolve(join(projectRoot, "app/frontend/shared/components")),
      "@images": resolve(join(projectRoot, "app/frontend/images")),
      // See config/vite.rb for where these are set
      // https://vite-ruby.netlify.app/config/#ruby-configuration-file-💎
      "@formtastic": process.env.FORMTASTIC_STYLESHEET_PATH,
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
    // This hides the "Download the Vue Devtools extension" message from the console
    onConsoleLog(log) {
      if (log.includes("Download the Vue Devtools extension")) return false;
    },
  },
});
