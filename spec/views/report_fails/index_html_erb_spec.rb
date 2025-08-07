# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'report_fails/index.html.erb' do
  include AuthenticatedSystem

  let(:user) { create(:user) }

  context 'when rendering the index' do
    let(:current_user) { user }
    let(:report_fail) { ReportFail.new(nil, nil, []) }
    let(:options) { %w[sample_integrity quantification lab_error] }

    before do
      assign(:report_fail, report_fail) # sets @widget = Widget.new in the view template
    end

    it 'renders the options' do
      render
      options.each { |key| expect(rendered).to match(key) }
    end
  end
end
