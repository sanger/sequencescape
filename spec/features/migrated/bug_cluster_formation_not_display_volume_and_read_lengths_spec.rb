# frozen_string_literal: true

require 'rails_helper'

# This test verifies that given the correct request information types
# configured, such as read length, library type, and concentration, the
# squencing pipeline batch page dispays these fields.

RSpec.feature 'Cluster formation pipeline batch displays read length and library type', :batch, :pipeline do
  let(:user) { create(:admin) }
  let(:request_information_types_data) do
    # [name, key, label, hide_in_inbox]
    [
      ['Read length', 'read_length', 'Read length', 0],
      ['Library type', 'library_type', 'Library type', 0],
      ['Concentration', 'concentration', 'Vol.', 0]
    ]
  end

  # Sequencing pipeline configuration close to Cluster formation SE,
  # for checking the display of read length, library type, and volume options.
  let(:pipeline) do
    create(:sequencing_pipeline).tap do |p|
      request_information_types_data.each do |name, key, label, hide_in_inbox|
        rit = create(:request_information_type, name:, key:, label:, hide_in_inbox:)
        create(:pipeline_request_information_type, pipeline: p, request_information_type: rit)
      end
    end
  end

  let(:request_parameters) do
    {
      request_type: pipeline.request_types.last,
      request_metadata: create(:request_metadata),
      asset: create(:library_tube)
    }
  end

  before do
    login_user(user)
    create(:request_with_submission, request_parameters)
      .tap { |request| request.asset.labware.create_scanned_into_lab_event!(content: '2025-06-20') }
  end

  scenario 'Make training batch' do
    visit root_path

    click_on 'Pipelines'
    click_on pipeline.name

    # Available requests
    expect(page).to have_content('Read length')
    expect(page).to have_content('Library type')
    expect(page).to have_content('Vol.')
  end
end
