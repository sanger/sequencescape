# frozen_string_literal: true

require 'rails_helper'
require 'lib/mock_parser'

RSpec.describe WorkingDilutionPlate, type: :model do
  describe 'update_qc_values_with_parser' do
    let(:readings) do
      {
        'B1' => { 'concentration' => Unit.new('2 ng/ul'), 'molarity' => Unit.new('3 nM'), 'volume' => Unit.new('20 ul'), 'RIN' => Unit.new('6 RIN') },
        'C1' => { 'concentration' => Unit.new('4 ng/ul'), 'molarity' => Unit.new('5 nM'), 'volume' => Unit.new('20 ul'), 'RIN' => Unit.new('6 RIN') }
      }
    end
    let(:plate) { create :working_dilution_plate, well_count: 3, well_factory: :empty_well, parents: [parent], dilution_factor: 10 }
    let(:parent) { create :plate, well_count: 3 }
    let(:parser) { MockParser.new(readings) }

    before do
      plate.update_qc_values_with_parser(parser)
    end

    it 'updates its well concentrations' do
      wells = plate.wells.includes(:map, :well_attribute).index_by(&:map_description)
      expect(wells['B1'].get_concentration).to eq 2
    end

    it 'updates its well molarity' do
      wells = plate.wells.includes(:map, :well_attribute).index_by(&:map_description)
      expect(wells['B1'].get_molarity).to eq 3
    end

    it 'updates its well volume' do
      wells = plate.wells.includes(:map, :well_attribute).index_by(&:map_description)
      expect(wells['B1'].get_volume).to eq 20
    end

    it 'updates its well rin' do
      wells = plate.wells.includes(:map, :well_attribute).index_by(&:map_description)
      expect(wells['B1'].get_rin).to eq 6
    end

    it 'updates its parent plate concentration (scaled)' do
      wells = parent.wells.includes(:map, :well_attribute).index_by(&:map_description)
      expect(wells['B1'].get_concentration).to eq 20
    end

    it 'updates its parent plate rin (absolute)' do
      wells = parent.wells.includes(:map, :well_attribute).index_by(&:map_description)
      expect(wells['B1'].get_rin).to eq 6
    end

    it 'does not update its parent plate volume' do
      wells = parent.wells.includes(:map, :well_attribute).index_by(&:map_description)
      expect(wells['B1'].get_volume).to eq 15.0
    end
  end
end
