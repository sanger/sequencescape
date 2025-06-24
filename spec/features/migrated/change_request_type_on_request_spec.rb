# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'if request is pending then the admin could change of request type.', :js, :request do
  let(:user) { create(:admin) }
  let(:project) { create(:project, name: 'Test project 10071597', enforce_quotas: true) }
  let(:lane) { create(:lane, name: 'NPG_Action_Lane_Test', qc_state: 'passed') }
  let(:library_tube) { create(:empty_library_tube) }
  let(:request_type) do
    create(:request_type, name: 'Paired end sequencing', request_class_name: 'SequencingRequest')
  end
  let(:request) do
    create(
      :request,
      asset: library_tube,
      target_asset: lane,
      state: 'pending',
      project: project,
      request_type: request_type
    )
  end

  before do
    login_user(user)
  end

  scenario 'The request is not pending. We should not see Request Type combo.' do
    request.update!(state: 'started')
    visit edit_request_path(request)
    expect(page).to have_content('Edit your request')
    expect(page).to have_no_content('Request Type:')
  end

  scenario 'Request is pending. I should see combobox Request Type. No change. it should work properly' do
    visit edit_request_path(request)
    expect(page).to have_content('Request Type:')
    click_on 'Save Request'
    expect(page).to have_content('Request details have been updated')
  end

  context 'with another request type' do
    before do
      create(:request_type, name: 'Single ended sequencing', request_class_name: 'SequencingRequest')
    end

    scenario 'The user asks to change with Request Type' do
      visit edit_request_path(request)
      expect(page).to have_content('Request Type:')
      select 'Single ended sequencing', from: 'Request Type:'
      click_on 'Save Request'
      expect(page).to have_content('Request details have been updated')
    end
  end
end
