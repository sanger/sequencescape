<!--
  Provides a help button which can be clicked to expand into a guide.
-->
<template>
  <section>
    <h2>Picks</h2>
    <div v-if="empty">Start scanning plates to see the associated picks</div>
    <PicksSectionBatch v-for="batch in batches" :key="batch.id" v-bind="batch" />
  </section>
</template>

<script>
import PicksSectionBatch from "./PicksSectionBatch.vue";

export default {
  components: {
    PicksSectionBatch,
  },
  data: function () {
    return {};
  },
  computed: {
    empty() {
      return Object.keys(this.$store.state.batches).length === 0;
    },
    batches() {
      return this.$store.getters.denormalizedBatches;
    },
  },
  methods: {},
};
</script>

<style scoped></style>
