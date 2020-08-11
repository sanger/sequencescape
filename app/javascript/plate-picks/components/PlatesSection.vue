<!--
  Provides a help button which can be clicked to expand into a guide.
-->
<template>
  <section>
    <h2>Plates</h2>
    <table class="table table-striped">
      <thead>
        <th>Barcode</th>
        <th>Status</th>
        <th>Picks</th>
      </thead>
      <tbody>
        <tr
          v-for="plate in plates"
          :key="plate.barcode"
          :class="`table-${plate.status}`"
        >
          <td>{{ plate.barcode }}</td>
          <td>{{ plate.status }}</td>
          <td>
            <span v-if="plate.message">{{ plate.message }}</span>
            <span
              v-for="pick in plate.picks"
              :key="pick.name"
            >{{ pick.name }}</span>
          </td>
        </tr>
      </tbody>
      <tfoot>
        <td>
          <input
            id="scan-plate"
            v-model="scannedBarcode"
            @blur="plateBarcodeScan"
          >
        </td>
        <td colspan="2">
          <label for="scan-plate">Scan a plate</label>
        </td>
      </tfoot>
    </table>
  </section>
</template>

<script>
export default {
  components: {
  },
  data: function () {
    return {
      scannedBarcode: ''
    }
  },
  computed: {
    plates () { return this.$store.state.plates }
  },
  methods: {
    plateBarcodeScan () {
      const last_scan = this.scannedBarcode.trim()
      if (last_scan === '') { return }
      this.scannedBarcode = ''
      this.$store.dispatch('plateBarcodeScan', last_scan)
    }
  }
}
</script>

<style scoped>

</style>
