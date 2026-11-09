# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Recycling requests in the Cherrypicking pipeline', :js do
  include BatchFeatureHelpers

  let(:user) { create(:admin, login: 'John Smith', first_name: 'John', last_name: 'Doe') }
  let(:pipeline) { create_batch_feature_pipeline('Cherrypick') }
  let(:study) { create(:study, name: 'Testing batch request recycling', state: 'pending') }
  let(:project) { create(:project, name: 'Testing batch request recycling') }
  let(:plate) { create(:plate) }

  before do
    pipeline
    project
    study.activate!
    asset_group = study.asset_groups.create!(name: 'My asset group')
    asset_group.assets = Array.new(5) { |index| create(:well, plate: plate, map: Map.map_96wells[index]) }
    template = create(:cherrypick_submission_template, request_types: [pipeline.request_types.first])
    template.create_with_submission!(
      project: project,
      study: study,
      asset_group: asset_group,
      user: user,
      request_options: {
        'asset_group' => 'My asset group',
        'project' => project.name,
        'study' => study.name
      }
    ).submission.built!
    process_batch_submission_jobs(1)

    # This purpose is normally seeded. There must be a valid output purpose even
    # on the initial template page, before any scenario-specific template exists.
    create(:stock_plate_purpose, name: 'Stock Plate', cherrypickable_target: true)
    login_user(user)
    visit_batch_pipeline(pipeline)
    create_batch_from_first_inbox_group
    click_link 'Select Plate Template'
    click_button 'Next'
  end

  [5, 3].each do |number_to_remove|
    it "returns #{number_to_remove} scratch-pad wells to the inbox when the layout is approved" do
      original_batch = Batch.last
      original_requests = original_batch.requests.to_a
      robot = create(:robot)
      robot.robot_properties.create!(key: 'max_plates', value: '21')
      create(:plate_template, name: 'My plate template')
      stub_request(:post, "#{configatron.baracoda_api}/barcodes/#{configatron.plate_barcode_prefix}/new")
        .to_return(status: 201, headers: { 'Content-Type' => 'text/json' },
                   body: { barcode: 'SQPD-1234567', format: nil }.to_json)

      visit_batch_pipeline(pipeline)
      click_link 'In progress'
      click_link 'View in progress batch 1'
      click_link 'Select Plate Template'
      select 'My plate template', from: 'Plate Template'
      click_button 'Next step'

      scratch_pad = find('#scratch_pad tr:first-child td:first-child')
      removed_request_ids = Array.new(number_to_remove) do
        source = first('#plate_1 td.colour0')
        source_id = source[:id]
        source.drag_to(scratch_pad)
        within('#scratch_pad') { expect(page).to have_css("##{source_id}") }
        source_id.delete_prefix('well_').to_i
      end
      click_button 'Next step'
      expect(page).to have_text("Batch #{original_batch.id} has completed the 'Cherrypick' pipeline.")

      visit_batch_pipeline(pipeline)
      within('#pipeline_inbox') { expect(page).to have_css('td.request', count: 1) }
      create_batch_from_first_inbox_group

      # Cucumber's one-column table compares the Wells column, not the unrelated
      # barcode, ID, plate link and purpose columns of the input asset table.
      rows = fetch_table('#input_assets')
      wells_column = rows.first.index('Wells')
      expect(wells_column).not_to be_nil
      expect(rows.map { |row| [row.fetch(wells_column)] }).to eq([['Wells'], [number_to_remove.to_s]])

      new_batch = Batch.last
      expect(new_batch).not_to eq(original_batch)
      expect(new_batch.requests.pluck(:id)).to match_array(removed_request_ids)
      expect(new_batch.requests.pluck(:state)).to all(eq('pending'))
      retained_request_ids = original_requests.map(&:id) - removed_request_ids
      expect(original_batch.reload.requests.pluck(:id)).to match_array(retained_request_ids)
    end
  end
end
