# frozen_string_literal: true

module ReportFailsHelper
  FAILURE_KEYS = %w[
    fail_because_sample_integrity
    fail_because_quantification
    fail_because_lab_error
  ].freeze
  def report_fail_failure_options
    FAILURE_KEYS.each_with_object({}) do |val, obj|
      obj[I18n.t("report_fails.#{val}")] = val
    end
  end

  def report_fail_selected_option
    FAILURE_KEYS.first
  end

  def report_fail_disabled_options
    []
  end
end
