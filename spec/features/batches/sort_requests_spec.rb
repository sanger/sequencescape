# frozen_string_literal: true

require 'rails_helper'
require 'pry'

describe 'Batches controller', :js, :warren do
  let(:request_count) { 3 }
  let(:batch) { create(:sequencing_batch, request_count: request_count, created_at: 1.day.ago, updated_at: 1.day.ago) }
  let(:user) { create(:admin) }
  let!(:flowcell_message) { create(:flowcell_messenger, target: batch) }

  it 'reordering requests' do
    requests_ids = batch.batch_requests.map(&:request_id)
    login_user user
    visit batch_path(batch)
    click_link('Edit batch')
    request_list = find_by_id('requests_list')
    expect(request_list).to have_css('tr', count: request_count)
    first_request, _second_request, third_request = *request_list.all('tr')

    # drag_to seems to be dragging up but not down
    # JG: Oddly prior to the Rails 5.2 update this was the other way round.
    # Suspect this is due to the quite specific locations at which the rows can be dropped.
    third_request.drag_to first_request

    expect(request_list.all('tr').first).to eq(third_request)

    post_drag = [requests_ids[2], requests_ids[0], requests_ids[1]]
    Warren.handler.clear_messages
    click_button('Save')
    request_list
      .all('tr')
      .each_with_index { |request, index| expect(request.text).to include((index + 1).to_s, post_drag[index].to_s) }

    expect(Warren.handler.messages_matching("queue_broadcast.messenger.#{flowcell_message.id}")).to be 1
    expect(flowcell_message.as_json.dig('flowcell', 'updated_at')).to be > 5.minutes.ago
  end

  it 'request zero comments link' do
    login_user user
    visit batch_path(batch)
    request_list = find_by_id('requests_list')
    td = request_list.first('tr').all('td').last
    expect(td).to have_link('0 comments')
  end
end
