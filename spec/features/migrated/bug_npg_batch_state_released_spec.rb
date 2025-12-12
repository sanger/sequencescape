# frozen_string_literal: true

require 'rails_helper'

# This test verifies that NPG lane's qc_state can be changed via the XML API.

RSpec.feature 'NPG batch state released via XML API', :allow_rescue, :api, :xml do
  let(:user) { create(:admin) }
  let(:lane) { create(:lane, name: 'NPG_Action_Lane_Test', qc_state: 'passed', external_release: 1) }
  let(:library_tube) { create(:library_tube) }
  let(:pipeline) { create(:sequencing_pipeline) }
  let(:request) do
    create(:request_with_sequencing_request_type,
           asset: library_tube, target_asset: lane,
           request_type: pipeline.request_types.last, state: 'started')
  end
  let(:batch) { create(:batch, state: 'started', qc_state: 'qc_manual', pipeline: pipeline) }

  before do
    login_user(user)
    create(:batch_request, request: request, batch: batch, position: 1)
  end

  scenario 'POST XML to change qc_state on an asset' do
    visit batch_path(batch)
    expect(page).to have_content('started')

    # to_xml accepts string or symbol keys; root element is set to remove 'hash' from the generated XML
    xml = { qc_information: { message: 'NPG change status in failed' } }.to_xml(root: 'qc_information')
    path = "/npg_actions/assets/#{lane.id}/pass_qc_state"
    headers = { 'HTTP_ACCEPT' => 'application/xml', 'CONTENT_TYPE' => 'application/xml' }
    page.driver.post path, xml, headers

    expect(page.status_code).to eq(200)

    hash = Hash.from_xml(page.body) # string keys
    expect(hash['asset']['qc_state']).to eq('passed')

    visit batch_path(batch)
    expect(page).to have_content("Pipeline #{pipeline.name}")
    expect(page).to have_content('released')
  end
end
