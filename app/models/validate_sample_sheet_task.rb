# Used in {PacBioSequencingPipeline}, used to validate the CSVs that get generated
# to drive the machine. These files aren't compatible with the newer PacBIo machines though.
class ValidateSampleSheetTask < Task
  def partial
    'validate_sample_sheet_batches'
  end

  def render_task(workflows_controller, params, _user)
    super
    workflows_controller.render_validate_sample_sheet_task(self, params)
  end

  def do_task(workflows_controller, params, _user)
    workflows_controller.do_validate_sample_sheet_task(self, params)
  end
end
