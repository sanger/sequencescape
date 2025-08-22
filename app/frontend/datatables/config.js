const defaults = {
  paging: false,
  fixedHeader: true,
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
