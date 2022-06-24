<!--
## Plate-picks

Provides an interactive interface to quickly sort plates into groups
based on the pick-lists they are associated with.

Accessed via: /plate_picks
Ruby side provided by PlatePicksController

Behaviour based on a spreadsheet originally built by: Eloise W

See: https://github.com/sanger/sequencescape/issues/2860
-->
<template>
  <div id="app">
    <help-toggle>
      <h3>Help</h3>
      <ol>
        <li>Ensure the 'Plate scan' box is selected</li>
        <li>Scan your plate into the search box using a barcode scanner</li>
        <li>Sequencescape will retrieve the plate information, and any associated batches</li>
        <li>
          This process may take a few moments for the first plate you scan, but should be substantially faster for
          subsequent plates in the same batch.
        </li>
        <li>
          <ul>
            <li>
              <i class="fas fa-clock" />
              Information about the plate is still being retrieved. The plate will be amber.
            </li>
            <li>
              <i class="fas fa-check" />
              If the plate is in a single pick, the plate will turn green, and the pick will be listed. If the sound is
              turned on, the pick name will be read out.
            </li>
            <li>
              <i class="fas fa-check-double" />
              If the plate is in a multiple pick, the plate will turn blue, and the picks will be listed. If the sound
              is turned on, the pick names will be read out.
            </li>
            <li>
              <i class="fas fa-times" />
              If the plate is not in a pick, the plate will turn grey.
            </li>
            <li>
              <i class="fas fa-vial" />
              If the plate is a control its picks will not be shown and instead it will indicate control. This is
              beacuse control plates are used in a large number of picks, and attempting to display them all would be
              impractical. The plate will turn grey.
            </li>
            <li>
              <i class="fas fa-exclamation-triangle" />
              Indicates something went wrong, or the plate could not be found.
            </li>
          </ul>
        </li>
        <li>
          The right hand side of the screen will display all picks in the same batch as the plate. Any plates which have
          been scanned in to the left hand side will be green and ticked.
        </li>
        <li>Proceed to scan in the next plate</li>
      </ol>
    </help-toggle>
    <BaseRadio
      id="notifyMode"
      v-model="notifyMode"
      :options="[
        { value: 'short', label: 'Short pick names' },
        { value: 'long', label: 'Long pick names' },
      ]"
      name="notifyMode"
      :inline="true"
    />
    <div id="sections">
      <plates-section id="plates-section" />
      <picks-section id="picks-section" />
    </div>
  </div>
</template>

<script>
import HelpToggle from "./components/HelpToggle.vue";
import PicksSection from "./components/PicksSection.vue";
import PlatesSection from "./components/PlatesSection.vue";

export default {
  components: {
    "help-toggle": HelpToggle,
    "picks-section": PicksSection,
    "plates-section": PlatesSection,
  },
  data: function () {
    return {};
  },
  computed: {
    notifyMode: {
      get() {
        return this.$store.state.options.notifyMode.mode;
      },
      set(value) {
        this.$store.commit("updateNotifyMode", { mode: value });
      },
    },
  },
};
</script>

<style scoped>
#sections {
  display: flex;
}
#plates-section {
  flex-grow: 1;
  padding: 1em;
}
#picks-section {
  flex-grow: 1;
  padding: 1em;
}
</style>
