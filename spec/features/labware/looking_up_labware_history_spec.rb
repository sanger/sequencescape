# frozen_string_literal: true

require 'rails_helper'

describe 'See labware history' do
  let(:user) { create :admin }
  let(:tube) { create :tube }

  before do
    create :asset_audit, asset: tube, created_at: Time.zone.parse('June 16, 2020 15:36')
  end

  it 'displays asset audits' do
    login_user(user)
    visit labware_path(tube)
    click_link 'Event history'
    expect(page).to have_content 'Event History'
    table = fetch_table('table#asset_audits')
    expect(table).to eq(
      [
        ['Message', 'Key', 'Created at', 'Created by'],
        ['Some message', 'some_key', 'June 16, 2020 15:36', 'abc123']
      ]
    )
  end
end
