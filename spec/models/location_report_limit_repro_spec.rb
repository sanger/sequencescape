# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LocationReport do
  let(:location_report) do
    build(
      :location_report,
      report_type: 'type_selection',
      name: 'Test Report',
      start_date: '2023-01-01',
      end_date: '2023-01-02',
      faculty_sponsor_ids: [1]
    )
  end

  before do
    allow(Labware).to receive(:search_for_count_of_labware).and_return(25_001)
  end

  it 'is invalid when too many labwares are found' do
    expect(location_report).not_to be_valid
    expect(location_report.errors[:base]).to include(I18n.t('location_reports.errors.too_many_labwares_found',
                                                            count: 25_001))
  end
end
