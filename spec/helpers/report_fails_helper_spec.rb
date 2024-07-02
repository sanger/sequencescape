# frozen_string_literal: true

require 'spec_helper'
require './app/helpers/report_fails_helper'
describe ReportFailsHelper do
  describe '#report_fail_failure_options' do
    it 'returns the available options' do
      expect(helper.report_fail_failure_options.values).to eq(%w[sample_integrity quantification lab_error])
    end
  end
end
