<!--
  Provides a help button which can be clicked to expand into a guide.
-->
<template>
  <section>
    <button :class="btnClass" @click="toggleVisibility">{{ visible ? "Hide" : "Show" }} help</button>
    <article v-if="visible" class="col">
      <div class="alert alert-user_guide">
        <slot />
      </div>
    </article>
  </section>
</template>

<script>
export default {
  data: function () {
    return { visible: false };
  },
  computed: {
    btnClass() {
      return { btn: true, "btn-success": !this.visible, "btn-danger": this.visible };
    },
  },
  methods: {
    toggleVisibility: function () {
      this.visible = !this.visible;
    },
  },
};
</script>

<style scoped>
article {
  margin: 1em;
}
</style>
