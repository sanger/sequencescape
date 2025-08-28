# frozen_string_literal: true

require 'rails_helper'

describe 'Show plate', :js do
  context 'when the plate has samples' do
    let(:plate) { create(:plate, well_count: 3) }
    let(:user) { create(:user) }

    before do
      plate # has been created
    end

    it 'shows the samples table with empty wells' do
      login_user user
      visit labware_path(plate)
      expect(fetch_table('#plate-samples-table')).to eq(
        [
          ['Well', 'Sample Name', 'Sanger Sample Id', 'Sample Supplier Name', 'Tag', 'Tag2', 'Control?'],
          ['A1', '[Empty]', '', '', '', '', ''],
          ['B1', '[Empty]', '', '', '', '', ''],
          ['C1', '[Empty]', '', '', '', '', '']
        ]
      )
    end
  end

  context 'when the plate does not have samples with supplier names and is not a cherrypickable_target' do
    let(:plate) { create(:plate, well_count: 3) }
    let(:user) { create(:user) }

    before do
      plate # has been created
      plate.plate_purpose.update!(cherrypickable_target: false) # When false, the plate should not show supplier names
    end

    it 'does not show the sample supplier name' do
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
end
