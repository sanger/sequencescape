import Sortable from "sortablejs";

document.querySelectorAll("table.plate tbody tr").forEach((tr) => {
  Sortable.create(tr, { group: "wells" });
});
