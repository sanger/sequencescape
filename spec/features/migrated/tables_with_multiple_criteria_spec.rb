# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Order a table with tablesorter plugin', :js, :pipeline do
  let(:user) { create(:admin) }

  before do
    login_user(user)
    pipeline = create(:sequencing_pipeline, name: 'MiSeq sequencing')
    5.times do |i|
      request_parameters = {
        request_type: pipeline.request_types.last,
        request_metadata: create(:request_metadata),
        asset: create(:library_tube, name: "Test Asset #{i}")
      }
      create(:request_with_submission, request_parameters)
        .tap { |request| request.asset.labware.create_scanned_into_lab_event!(content: '2025-06-20') }
    end
    visit pipeline_path(pipeline)
  end

  scenario 'Order the table clicking "Name" column' do
    find('th', text: 'Name').click

    expected_order = [
      'Test Asset 0',
      'Test Asset 1',
      'Test Asset 2',
      'Test Asset 3',
      'Test Asset 4'
    ]
    name_index = all('table thead tr th').map(&:text).index('Name')

    actual_order = all('table tbody tr').map do |row|
      row.all('td')[name_index]&.text
    end
    expect(actual_order).to eq(expected_order)

    find('th', text: 'Name').click

    expected_order.reverse!
    actual_order = all('table tbody tr').map do |row|
      row.all('td')[name_index]&.text
    end
    expect(actual_order).to eq(expected_order)
  end
end
