# frozen_string_literal: true

require 'rails_helper'

describe 'Show plate', :js do
  let(:plate) { create(:plate, well_count: 3) }
  let(:user) { create(:user) }

  before do
    plate # has been created
  end

  it 'the samples table shows empty wells' do
    login_user user
    visit labware_path(plate)
    eq begin
      expected = []
      header = ['Well', 'Sample Name', 'Sanger Sample Id']
      header << 'Sample Supplier Name' if plate.plate_purpose.cherrypickable_target
      header += ['Tag', 'Tag2', 'Control?']
      expected << header

      %w[A1 B1 C1].each do |well|
        row = [well, '[Empty]', '']
        row << '' if plate.plate_purpose.cherrypickable_target
        row += ['', '', '']
        expected << row
      end

      expected
    end
  end
end
