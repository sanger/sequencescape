/* eslint no-console: 0 */
// Run this example by adding <%= javascript_pack_tag 'hello_vue' %> (and
// <%= stylesheet_pack_tag 'hello_vue' %> if you have styles in your component)
// to the head of your layout file,
// like app/views/layouts/application.html.erb.
// All it does is render <div>Hello Vue</div> at the bottom of the page.

import Vue from 'vue'
import Vuex from 'vuex'
import App from './app.vue'
import storeConfig from './store'

Vue.use(Vuex)

const store = new Vuex.Store({
  strict: process.env.NODE_ENV !== 'production',
  ...storeConfig
})

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#plate-picks-app',
    render: h => h(App),
    store
  })
})
