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
});
