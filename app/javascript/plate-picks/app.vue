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
      This is the help text.
    </help-toggle>
    <div id="sections">
      <plates-section id="plates-section" />
      <picks-section id="picks-section" />
    </div>
  </div>
</template>

<script>
import HelpToggle from './components/HelpToggle.vue'
import PicksSection from './components/PicksSection.vue'
import PlatesSection from './components/PlatesSection.vue'

export default {
  components: {
    'help-toggle': HelpToggle,
    'picks-section': PicksSection,
    'plates-section': PlatesSection
  },
  data: function () {
    return {
      plates: [],
      picks: {}
    }
  }
}
</script>

<style scoped>
  #sections { display: flex; }
  #plates-section { flex-grow: 1; }
  #picks-section { flex-grow: 1; }
</style>
