# frozen_string_literal: true

require 'rails_helper'
require 'pry'

describe 'Batches controller', js: true do
  let(:request_count) { 3 }
  let(:batch) { create :batch, request_count: request_count }
  let(:user) { create :admin }

  it 'reordering requests' do
    requests_ids = batch.batch_requests.map(&:request_id)
    login_user user
    visit batch_path(batch)
    click_link('Edit batch')
    request_list = find('#requests_list')
    expect(request_list).to have_css('tr', count: request_count)
    first_request, _second_request, third_request = *request_list.all('tr')

    # drag_to seems to be dragging up but not down
    # JG: Oddly prior to the Rails 5.2 update this was the other way round.
    # Suspect this is due to the quite specific locations at which the rows can be dropped.
    third_request.drag_to first_request
    expect(request_list.all('tr').first).to eq(third_request)

    post_drag = [requests_ids[2], requests_ids[0], requests_ids[1]]
    click_link('Finish editing')
    request_list
      .all('tr')
      .each_with_index { |request, index| expect(request.text).to include((index + 1).to_s, (post_drag[index]).to_s) }
  end
end
