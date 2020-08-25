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
      :class="['card-header', `colour-${id}`]"
    >
      {{ name }}
    </div>
    <ul class="list-group list-group-flush">
      <li
        v-for="plate in plates"
        :key="plate.barcode"
        :class="{
          'list-group-item': true,
          'list-group-item-success': plate.scanned
        }"
      >
        <i :class="`fas fa-${plate.scanned ? 'check' : ''}`" /> {{ plate.barcode }}
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
  name: 'PicksSectionBatchPick',
  props: {
    name: {
      type: String,
      required: true
    },
    id: {
      type: [String, Number],
      required: true
    },
    plates: {
      type: Array,
      required: true
    }
  },
  data: function () {
    return { }
  },
  computed: {}
  // methods: {},
}
</script>

<style scoped>

</style>
