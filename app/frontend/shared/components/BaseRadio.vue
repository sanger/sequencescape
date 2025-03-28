<!--
  BaseRadio

  As this is a base component, it is suggested you import it globaly

  Usage:
  import BaseRadio from '@sharedComponents/BaseRadio'
  Vue.component('BaseRadio', BaseRadio)

    <template>
      <div><BaseRadio
        id="notifyMode"
        v-model="notifyMode"
        :options="[
          { value: 'short', label: 'Short pick names' },
          { value: 'long', label: 'Long pick names' }
        ]"
        name="notifyMode"
        :inline="true"
    /></div>
    </template>
-->
<template>
  <div>
    <div v-for="option in options" :key="option.value" :class="styles">
      <input
        :id="`${id}-${option.value}`"
        v-model="value"
        type="radio"
        :name="name"
        class="custom-control-input"
        :value="option.value"
        @change="change"
      />
      <label class="custom-control-label" :for="`${id}-${option.value}`">{{ option.label }}</label>
    </div>
  </div>
</template>

<script>
// Imports

// Component
// See https://vuejs.org/v2/style-guide/#Component-instance-options-order-recommended
// for order of other options
export default {
  name: "BaseRadio",
  model: {
    prop: "selected",
    event: "change",
  },
  props: {
    options: { type: Array, required: true }, // Array of objects { value: 'option value', label: 'Displayed label' }
    selected: { type: [Number, String], required: false, default: null },
    inline: { type: Boolean, required: false, default: false },
    name: { type: String, required: true },
    id: { type: String, required: true }, // Unique id essential for generating labels
  },
  emits: ["change"],
  data: function () {
    return {
      value: this.selected,
    };
  },
  computed: {
    styles() {
      return {
        "custom-control": true,
        "custom-radio": true,
        "custom-control-inline": this.inline,
      };
    },
  },
  methods: {
    change() {
      this.$emit("change", this.value);
    },
  },
};
</script>

<style scoped></style>
