<!--
  PicksSectionBatchPick
  Usage:
    <template>
      <div><PicksSectionBatchPick v-bind="pick"/></div>
    </template>

    <script>
    import PicksSectionBatchPick from './path-to/PicksSectionBatchPick'
    export default {
      components: {
        PicksSectionBatchPick
      }
    }
    </script>
-->
<template>
  <div>
    <div
      :id="`pick-${id}`"
      :class="['card-header', `colour-${id}`, 'd-flex', 'justify-content-between', 'align-items-center']"
    >
      <h5>{{ name }}</h5>
      <div>
        <input v-model="shortName" class="form-control" />
      </div>
    </div>
    <ul class="list-group list-group-flush">
      <li
        v-for="plate in plates"
        :key="plate.barcode"
        :class="{
          'list-group-item': true,
          'list-group-item-success': plate.scanned,
        }"
      >
        <i :class="`fas fa-${plate.scanned ? 'check' : ''}`" />
        <i v-if="plate.control" class="fas fa-vial" />
        {{ plate.barcode }}
      </li>
    </ul>
  </div>
</template>

<script>
// Imports

// Component
// See https://vuejs.org/v2/style-guide/#Component-instance-options-order-recommended
// for order of other options
export default {
  name: "PicksSectionBatchPick",
  props: {
    name: {
      type: String,
      required: true,
    },
    short: {
      type: String,
      required: true,
    },
    id: {
      type: [String, Number],
      required: true,
    },
    plates: {
      type: Array,
      required: true,
    },
  },
  data: function () {
    return {};
  },
  computed: {
    shortName: {
      get() {
        return this.short;
      },
      set(value) {
        this.$store.commit("updatePick", { id: this.id, short: value });
      },
    },
  },
  // methods: {},
};
</script>

<style scoped></style>
