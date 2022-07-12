<!--
  PicksSectionBatch
  Usage:
    <template>
      <div><PicksSectionBatch v-bind="batch"/></div>
    </template>

    <script>
    import PicksSectionBatch from './path-to/PicksSectionBatch'
    export default {
      components: {
        PicksSectionBatch
      }
    }
    </script>
-->
<template>
  <div>
    <div v-if="message" :class="colourClass">
      <div class="card-body"><i :class="`fas fa-${icon}`" /> Batch {{ id }}: {{ message }}</div>
    </div>
    <PicksSectionBatchPick v-for="pick in picks" :key="pick.name" v-bind="pick" class="ss-card" />
  </div>
</template>

<script>
// Imports
import PicksSectionBatchPick from "./PicksSectionBatchPick.vue";
// Component
export default {
  name: "PicksSectionBatch",
  components: {
    PicksSectionBatchPick,
  },
  props: {
    id: {
      type: String,
      required: true,
    },
    errorMessage: {
      type: String,
      required: false,
      default: null,
    },
    picks: {
      type: Array,
      required: false,
      default: undefined,
    },
  },
  data: function () {
    return {};
  },
  computed: {
    state() {
      if (this.errorMessage) {
        return "error";
      } else if (!this.picks) {
        return "wait-batch";
      } else if (this.picks.length === 0) {
        return "no-pick";
      } else {
        return "success";
      }
    },
    message() {
      switch (this.state) {
        case "error":
          return this.errorMessage;
        case "wait-batch":
          return "Fetching batch information";
        case "no-pick":
          return "No picks found";
        default:
          return null;
      }
    },
    colourClass() {
      switch (this.state) {
        case "error":
          return "ss-card bg-danger text-white";
        case "wait-batch":
          return "ss-card bg-warning text-white";
        default:
          // We wont actually be drawing any cards here
          return "d-none";
      }
    },
    // The font-awesome status icon
    icon() {
      switch (this.state) {
        case "error":
          return "exclamation-triangle";
        case "wait-batch":
          return "clock";
        default:
          // We wont actually be drawing any cards here
          return null;
      }
    },
  },
  // methods: {},
};
</script>

<style scoped></style>
