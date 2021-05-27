# frozen_string_literal: true

require 'rails_helper'

describe 'See labware history' do
  let(:user) { create :admin }
  let(:tube) { create :tube }

  before do
    create :asset_audit,
           asset: tube,
           created_at: Time.zone.parse('June 16, 2020 15:36'),
           metadata: {
             'metadata key' => 'metadata value'
           }
  end

  it 'displays asset audits', js: true do
    login_user(user)
    visit labware_path(tube)
    click_link 'Event history'
    expect(page).to have_content 'Event History'

    table = fetch_table('table#asset_audits')
    expect(table).to eq(
      [
        ['Message', 'Key', 'Created at', 'Created by', 'Details'],
        ['Some message', 'some_key', 'June 16, 2020 15:36', 'abc123', 'metadata key metadata value']
      ]
    )
  end
end
