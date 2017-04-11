# frozen_string_literal: true
require 'rails_helper'
require 'pry'

feature 'Batches controller', js: true do
  let(:request_count) { 3 }
  let(:batch) { create :batch, request_count: request_count }
  let(:user)  { create :admin  }

  scenario 'reordering requests' do
    requests_ids = batch.batch_requests.map { |br| br.request_id }
    login_user user
    visit batch_path(batch)
    click_link('Edit batch')
    request_list = find('#requests_list')
    expect(request_list).to have_css('tr', count: request_count)
    first_request, second_request, third_request = *request_list.all('tr')
    # drag_to seems to be dragging down but not up
    # could not make "third_request.drag_to first_request" work
    first_request.drag_to third_request
    expect(request_list.all('tr').first).to eq(second_request)
    wait_for_ajax
    click_link('Finish editing')
    request_list.all('tr').each_with_index do |request, index|
      expect(request.text).to include((index + 1).to_s, (requests_ids.rotate(1)[index]).to_s)
    end
  end
end
