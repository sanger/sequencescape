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
        <td>DN12345</td><td>Scanned</td><td>Pick 1</td>
      </tbody>
      <tfoot>
        <td><input id="scan-plate"/></td>
        <td colspan="2"><label for="scan-plate">Scan a plate</label></td>
      </tfoot>
    </table>
  </section>
</template>

<script>
export default {
  data: function () {
    return { }
  },
  methods: {}
}
</script>

<style scoped>

</style>
