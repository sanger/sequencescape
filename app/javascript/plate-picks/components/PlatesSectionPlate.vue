<!--
  PlatesSectionPlate
  Usage:
    <template>
      <div><PlatesSectionPlate v-bind="plate"/></div>
    </template>

    <script>
    import PlatesSectionPlate from './path-to/PlatesSectionPlate'
    export default {
      components: {
        PlatesSectionPlate
      }
    }
    </script>
-->
<template>
  <tr :class="`table-${colourClass}`">
    <th scope="row">
      {{ barcode }}
    </th>
    <td><i :class="`fas fa-${icon}`" /></td>
    <td>
      <a
        v-for="pick in flatPicks"
        :key="pick.id"
        :class="['ss-badge-lg', `colour-${pick.id}`]"
        :href="`#pick-${pick.id}`"
        :title="pick.name"
        >{{ shortName ? pick.short : pick.name }}</a
      >
      <span v-if="message">{{ message }}</span>
    </td>
  </tr>
</template>

<script>
// Imports
// Helpers
const sumArrayLength = (total, array) => total + array.length;
// Component
export default {
  name: "PlatesSectionPlate",
  props: {
    barcode: {
      type: String,
      required: true,
    },
    batches: {
      type: Array,
      required: false,
      default: null,
    },
    picks: {
      type: Object,
      required: false,
      default: null,
    },
    control: {
      type: Boolean,
      required: false,
      default: false,
    },
    errorMessage: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    // Swith the state to avoid replicating the logic throughout
    state() {
      if (this.errorMessage) {
        return "error";
      } // Something went wrong
      else if (this.batches === null) {
        return "wait-plate";
      } // We're fetching the plate
      else if (this.control) {
        return "control";
      } // The plate is a control
      else if (this.pendingBatches) {
        return "wait-batch";
      } // We're fetching the plate
      else if (this.totalPicks === 1) {
        return "single-pick";
      } else if (this.totalPicks > 1) {
        return "multi-pick";
      } else {
        return "no-pick";
      }
    },
    // Bootstrap colour classes
    colourClass() {
      switch (this.state) {
        case "error":
          return "danger";
        case "wait-plate":
        case "wait-batch":
          return "warning";
        case "single-pick":
          return "success";
        case "multi-pick":
          return "primary";
        case "no-pick":
        case "control":
          return "secondary";
        default:
          // We really shouldn't end up here. If we do, somethings gone wrong.
          return "danger";
      }
    },
    // The font-awesome status icon
    icon() {
      switch (this.state) {
        case "error":
          return "exclamation-triangle";
        case "no-pick":
          return "times";
        case "wait-plate":
        case "wait-batch":
          return "clock";
        case "single-pick":
          return "check";
        case "multi-pick":
          return "check-double";
        case "control":
          return "vial";
        default:
          // We really shouldn't end up here. If we do, somethings gone wrong.
          return "error";
      }
    },
    // Indicatesss that pick information if pending for one or more batches
    pendingBatches() {
      const foundBatches = Object.keys(this.picks || {});
      return this.batches.filter((batch_id) => !foundBatches.includes(batch_id)).length > 0;
    },
    // Converts by batch pick information { 1: [{...},{...}]} into a flat array [{...},{...}]
    flatPicks() {
      return Object.values(this.picks || {}).flat();
    },
    totalPicks() {
      return Object.values(this.picks || {}).reduce(sumArrayLength, 0);
    },
    // User feedback of current state
    message() {
      switch (this.state) {
        case "error":
          return this.errorMessage;
        case "wait-plate":
          return "Fetching plate information";
        case "wait-batch":
          return "Fetching batch information";
        case "no-pick":
          return "No picks found";
        case "control":
          return "Control plate";
        default:
          return null;
      }
    },
    shortName() {
      return this.$store.state.options.notifyMode.mode === "short";
    },
  },
  // methods: {},
};
</script>

<style scoped></style>
