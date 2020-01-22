module ReportFailsHelper
  FAILURE_KEYS = [
    'fail_because_sample_integrity',
    'fail_because_quantification',
    'fail_because_lab_error'
  ]
  def report_fail_failure_options
    FAILURE_KEYS.reduce({}) do |obj, val|
      obj[I18n.t("report_fails.#{val}")] = val
      obj
    end
  end

  def report_fail_selected_option
    FAILURE_KEYS.first
  end

  def report_fail_disabled_options
    []
  end
end
