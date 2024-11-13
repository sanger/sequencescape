# frozen_string_literal: true

require 'rails_helper'
require 'pry'

describe 'Batches controller', :js do
  let(:request_count) { 3 }
  let(:plate) { create(:plate, well_count: 3) }
  let(:destination_plate) { create(:plate, well_count: 3) }
  let(:batch) do
    create(
      :cherrypick_batch,
      state: 'released',
      request_attributes: [
        { asset: plate.wells[0], target_asset: destination_plate.wells[0], state: 'passed' },
        { asset: plate.wells[1], target_asset: destination_plate.wells[1], state: 'passed' },
        { asset: plate.wells[2], target_asset: destination_plate.wells[2], state: 'passed' }
      ]
    )
  end
  let(:user) { create(:admin) }

  before { create(:robot) }

  it 'failing passed cherrypick requests' do
    request_ids = batch.batch_requests.map(&:request_id)
    login_user user
    visit batch_path(batch)
    click_link('Fail batch or requests')
    check('Fail request 1')
    check('Fail request 2')
    check('Fail request 3')

    select('Batch not needed', from: 'Select failure reason')
    fill_in('Comment', with: 'Test')
    click_on 'Fail selected requests'
    expect(page).to have_text('3 requests failed')

    # Limit ourselves to the table, as our request links can be a bit generic
    within('form .table') do
      request_ids.each do |id|
        expect(find_link(id.to_s).ancestor('tr')).to have_text('failed')
        request_window = window_opened_by { click_link(id.to_s) }
        within_window(request_window) { expect(page).to have_text 'failed' }
      end
    end
    visit batch_path(batch)
    expect(page).to have_text 'failed'
  end
end
