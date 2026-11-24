# frozen_string_literal: true
require 'rails_helper'

# This test verifies added (spiked in) PhiX as a control to a sequencing batch.

RSpec.feature 'Spiked in Control', :npg, :xml do
  let(:user) { create(:admin) }

  let(:spiked_buffer) do
    create(:spiked_buffer, name: 'Aliquot #1').tap do |buffer|
      buffer.parents << create(:phi_x_stock_tube, name: 'indexed phiX')
      buffer.barcodes << create(:sanger_ean13_tube, barcode: 'NP1G')
    end
  end

  # Create a sequencing pipeline with a workflow that includes the task
  # 'Add Spiked in control', similar to the 'Cluster formation PE (spiked in
  # controls)' pipeline.
  let(:pipeline) { create(:sequencing_pipeline, :with_workflow) }

  # Create a batch with pipeline and 8 requests
  let(:batch) do
    create(:sequencing_batch, pipeline: pipeline, request_count: 8, user: user,
                              request_factory: :request_with_sequencing_request_type)
  end

  before do
    login_user(user)
  end

  scenario 'Create a batch and check the xml' do
    visit batch_path(batch)

    click_link 'Add Spiked in control'
    fill_in 'Barcode', with: spiked_buffer.human_barcode

    uncheck 'sample-1-checkbox'
    check 'sample-2-checkbox'
    uncheck 'sample-3-checkbox'
    uncheck 'sample-4-checkbox'
    uncheck 'sample-5-checkbox'
    uncheck 'sample-6-checkbox'
    uncheck 'sample-7-checkbox'
    uncheck 'sample-8-checkbox'

    click_button 'Next step'

    click_button 'Next step'

    # Get XML for the batch
    page.driver.get batch_path(batch, format: :xml)
    hash = Hash.from_xml(page.body)

    lane = hash.dig('batch', 'lanes', 'lane')[1]
    expect(lane['position'].to_s).to eq('2') # ignore type
    expect(lane['library']['name']).to eq('Asset 2')
    expect(lane['library']['sample']['library_name']).to eq('Asset 2')
    expect(lane['hyb_buffer']['sample']['library_name']).to eq('Aliquot #1')
    expect(lane['hyb_buffer']['control']['name']).to eq('indexed phiX')
  end
end
