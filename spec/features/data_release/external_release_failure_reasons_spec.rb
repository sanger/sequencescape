# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'External release failure reasons', :data_release, :external_release do
  let(:user) { create(:admin) }

  before do
    login_user(user)
  end

  scenario 'shows reasons for releasing passed data' do
    lane = create(:lane, name: 'first_asset', qc_state: 'passed', external_release: true)

    visit receptacle_path(lane)
    click_link 'Edit'

    expect(page).to have_select(
      'Reason for releasing data',
      options: [''] + Lane::LIST_REASONS_POSITIVE
    )
  end

  scenario 'shows reasons for releasing failed data' do
    lane = create(:lane, name: 'second_asset', qc_state: 'failed', external_release: false)

    visit receptacle_path(lane)
    click_link 'Edit'

    expect(page).to have_select(
      'Reason for releasing data',
      options: [''] + Lane::LIST_REASONS_NEGATIVE
    )
  end

  scenario 'correctly updates the reason for releasing data' do
    lane = create(:lane, name: 'third_asset', qc_state: 'failed', external_release: false)

    visit receptacle_path(lane)
    click_link 'Edit'
    select Lane::LIST_REASONS_NEGATIVE.first, from: 'Reason for releasing data'
    click_button 'Update'

    expect(page).to have_current_path(receptacle_path(lane))
    expect(page).to have_text('Receptacle was successfully updated.')
    expect(page).to have_text(Lane::LIST_REASONS_NEGATIVE.first)
  end
end
