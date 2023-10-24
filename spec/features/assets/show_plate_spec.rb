# frozen_string_literal: true

require 'rails_helper'

describe 'Show plate', :js do
  let(:plate) { create :plate, well_count: 3 }
  let(:user) { create :user }

  before do
    plate # has been created
  end

  it 'the samples table shows empty wells' do
    login_user user
    visit labware_path(plate)
    expect(fetch_table('#plate-samples-table')).to eq(
      [
        ['Well', 'Sample Name', 'Sanger Sample Id', 'Tag', 'Tag2', 'Control?'],
        ['A1', '[Empty]', '', '', '', ''],
        ['B1', '[Empty]', '', '', '', ''],
        ['C1', '[Empty]', '', '', '', '']
      ]
    )
  end
end
