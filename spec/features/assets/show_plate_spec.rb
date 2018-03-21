# frozen_string_literal: true

require 'rails_helper'

feature 'Show plate', js: true do
  let(:plate) { create :plate, well_count: 3 }
  let(:user) { create :user }

  background do
    plate # has been created
  end

  scenario 'the samples table shows empty wells' do
    login_user user
    visit asset_path(plate)
    expect(fetch_table('#plate-samples-table')).to eq([
      ['Well', 'Sample Name', 'Sanger Sample Id', 'Tag', 'Tag2'],
      ['A1',   '[Empty]',     '',                 '',    ''],
      ['B1',   '[Empty]',     '',                 '',    ''],
      ['C1',   '[Empty]',     '',                 '',    '']
    ])
  end
end
