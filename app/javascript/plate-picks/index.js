/* eslint no-console: 0 */

import Vue from "vue";
import Vuex from "vuex";
import App from "./app.vue";
import storeConfig from "./store";
import BaseRadio from "@sharedComponents/BaseRadio.vue";

Vue.component("BaseRadio", BaseRadio);

Vue.use(Vuex);

const store = new Vuex.Store({
  strict: process.env.NODE_ENV !== "production",
  ...storeConfig,
});

document.addEventListener("DOMContentLoaded", () => {
  new Vue({
    el: "#plate-picks-app",
    render: (h) => h(App),
    store,
  });
});
