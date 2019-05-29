# frozen_string_literal: true

require 'rails_helper'
require 'support/lab_where_client_helper'

RSpec.configure do |c|
  c.include LabWhereClientHelper
end

describe 'Viewing an asset' do
  let(:user) { create :user }

  shared_examples 'an asset' do
    it 'can be viewed on its show page' do
      login_user user
      visit asset_path(asset)
      expect(find('h1')).to have_content("Asset #{asset.name}")
    end
  end

  context 'a sample tube' do
    let(:asset) { create :sample_tube }

    it_behaves_like 'an asset'
  end

  context 'a library_tube' do
    let(:asset) { create :library_tube }

    it_behaves_like 'an asset'
  end

  context 'a lane' do
    let(:asset) { create :lane }

    it_behaves_like 'an asset'
  end

  context 'a well' do
    let(:asset) { create :well }

    it_behaves_like 'an asset'
  end

  context 'a plate' do
    let(:asset) { create :plate, well_count: 2 }

    context 'in labwhere' do
      setup { stub_lwclient_labware_find_by_bc(lw_barcode: asset.machine_barcode, lw_locn_name: 'location', lw_locn_parentage: 'place > location') }
      it_behaves_like 'an asset'
    end

    context 'Not in labwhere' do
      setup do
        stub_lwclient_labware_find_by_bc(lw_barcode: asset.human_barcode)
        stub_lwclient_labware_find_by_bc(lw_barcode: asset.machine_barcode)
      end
      it_behaves_like 'an asset'
    end
  end
end
