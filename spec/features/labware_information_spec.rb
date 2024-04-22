# frozen_string_literal: true

require 'rails_helper'
require 'support/lab_where_client_helper'

RSpec.configure { |c| c.include LabWhereClientHelper }

describe 'Viewing labware' do
  let(:user) { create(:user) }

  shared_examples 'labware' do
    it 'can be viewed on its show page' do
      login_user user
      visit labware_path(labware)
      expect(find('h1')).to have_content("Labware #{labware.name}")
    end
  end

  context 'with a sample tube' do
    let(:labware) { create(:sample_tube) }

    it_behaves_like 'labware'
  end

  context 'with a library_tube' do
    let(:labware) { create(:library_tube) }

    it_behaves_like 'labware'
  end

  context 'with a lane' do
    let(:labware) { create(:lane).labware }

    it_behaves_like 'labware'
  end

  context 'with a plate' do
    let(:labware) { create(:plate, well_count: 2) }

    context 'when in labwhere' do
      before do
        stub_lwclient_labware_find_by_bc(
          lw_barcode: labware.machine_barcode,
          lw_locn_name: 'location',
          lw_locn_parentage: 'place > location'
        )
      end

      it_behaves_like 'labware'
    end

    context 'when not in labwhere' do
      before do
        stub_lwclient_labware_find_by_bc(lw_barcode: labware.human_barcode)
        stub_lwclient_labware_find_by_bc(lw_barcode: labware.machine_barcode)
      end

      it_behaves_like 'labware'
    end
  end
end
