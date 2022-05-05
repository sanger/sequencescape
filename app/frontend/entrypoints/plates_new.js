import $ from "jquery";
import select2 from "select2";
select2();

const defaultOption = "[1.0]";

const dataForName = (selectedOption) =>
  JSON.parse(selectedOption.dataset.validDilutionFactors || defaultOption).map((val) => ({
    id: val.toFixed(1),
    text: val.toFixed(1),
  }));

const updateFactorsFor = (selectedOption, target) => {
  target[0].options.length = 0;
  target.select2({
    theme: "bootstrap4",
    minimumResultsForSearch: -1,
    data: dataForName(selectedOption),
  });
};

$(() => {
  const dilutionFactorSelect = $("#plates_dilution_factor");

  $("#plates_creator_id")
    .on("change", (event) => {
      event.target.selectedOptions[0].dataset;
      updateFactorsFor(event.target.selectedOptions[0], dilutionFactorSelect);
    })
    .trigger("change");
});
