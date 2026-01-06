const defaults = {
  paging: false,
  fixedHeader: true,
  layout: {
    bottomStart: null, // Hide info text like "Showing 1 to 10 of 23 entries"
  },
  language: {
    paginate: {
      previous: "Previous",
      next: "Next",
    },
    lengthMenu: "Show _MENU_ entries",
  },
};

const cssSelectors = {
  DefaultConfig: "table.sortable:not(#pipeline_inbox),table#batch-show",
  BatchEditConfig: "table#batch-edit",
  PipelineInboxConfig: "table#pipeline_inbox",
  AjaxConfig: "table.sortable:not(#pipeline_inbox)",
};
export { defaults, cssSelectors };
