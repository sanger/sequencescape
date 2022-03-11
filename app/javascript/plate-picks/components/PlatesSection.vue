<!--
  Provides a help button which can be clicked to expand into a guide.
-->
<template>
  <section>
    <h2>Plates</h2>
    <table class="table table-striped table-sm">
      <thead>
        <th scope="col">Barcode</th>
        <th scope="col">Status</th>
        <th scope="col">Picks</th>
      </thead>
      <tbody>
        <PlatesSectionPlate v-for="plate in scannedPlates" :key="plate.barcode" v-bind="plate" />
      </tbody>
      <tfoot>
        <td>
          <input
            id="scan-plate"
            ref="scanPlate"
            v-model="scannedBarcode"
            class="form-control"
            @keydown.enter="plateBarcodeScan"
            @keydown.tab="plateBarcodeScan"
          />
        </td>
        <td colspan="2">
          <label for="scan-plate">Scan a plate</label>
        </td>
      </tfoot>
    </table>
  </section>
</template>

<script>
import PlatesSectionPlate from "./PlatesSectionPlate.vue";

export default {
  components: {
    PlatesSectionPlate,
  },
  data: function () {
    return {
      scannedBarcode: "",
    };
  },
  computed: {
    scannedPlates() {
      return this.$store.getters.scannedPlates;
    },
  },
  mounted() {
    this.$refs.scanPlate.focus();
  },
  methods: {
    plateBarcodeScan(event) {
      const last_scan = this.scannedBarcode.trim();
      if (last_scan === "") {
        return;
      }
      this.scannedBarcode = "";
      this.$store.dispatch("plateBarcodeScan", last_scan);
      // Prevent us from losing focus
      event.preventDefault();
    },
  },
};
</script>

<style scoped></style>
