// default for bootstrap with added buttons
const dom =
  "<'row'<'col-sm-12 col-md-6'l><'col-sm-12 col-md-6'f>><'row'<'col-sm-12'tr>><'row'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7'pB>>";

const defaults = { paging: false, order: [], buttons: [], dom, fixedHeader: true };

const cssSelectors = {
  DefaultConfig: "table.sortable:not(#pipeline_inbox),table#batch-show",
  BatchEditConfig: "table#batch-edit",
  PipelineInboxConfig: "table#pipeline_inbox",
  AjaxConfig: "table.sortable:not(#pipeline_inbox)",
};
export { dom, defaults, cssSelectors };
