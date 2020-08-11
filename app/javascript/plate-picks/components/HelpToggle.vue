<!--
  Provides a help button which can be clicked to expand into a guide.
-->
<template>
  <section>
    <button @click="toggleVisibility">
      {{ visible ? "Hide" : "Show" }} help
    </button>
    <article v-if="visible">
      <slot />
    </article>
  </section>
</template>

<script>
export default {
  data: function () {
    return { visible: false }
  },
  methods: {
    toggleVisibility: function () { this.visible = !this.visible }
  }
}
</script>

<style scoped>

</style>
