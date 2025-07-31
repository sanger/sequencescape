# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'labware/show.html.erb' do # rubocop:todo RSpec/DescribeClass
  include AuthenticatedSystem

  let(:user) { create(:user) }

  shared_examples 'retention instruction' do
    it 'displays retention key instruction in asset summary' do
      render
      expect(rendered).to match(/Retention Instruction/)
    end

    it 'displays retention instruction value in asset summary' do
      render
      expect(rendered).to match(/Destroy after 2 years/)
    end
  end

  context 'when rendering a plate' do
    let(:current_user) { user }
    let(:plate) { create(:plate_with_3_wells) }

    before do
      assign(:asset, plate) # sets @widget = Widget.new in the view template
    end

    it 'displays the barcode of the plate' do
      render
      expect(rendered).to match(plate.human_barcode)
    end

    it 'does not display the barcode for the wells' do
      render
      expect(rendered).not_to match(/Tube Barcode/)
    end

    context 'when retention instructions are coming from custom_metadata (for old submissions)' do
      before do
        custom_metadatum = CustomMetadatum.new
        custom_metadatum.key = 'retention_instruction'
        custom_metadatum.value = 'Destroy after 2 years'
        custom_metadatum_collection = CustomMetadatumCollection.new
        custom_metadatum_collection.custom_metadata = [custom_metadatum]
        custom_metadatum_collection.asset = plate
        custom_metadatum_collection.user = user
        custom_metadatum_collection.save!
        custom_metadatum.save!
      end

      it_behaves_like 'retention instruction'
    end

    context 'when retention instructions are coming from labware.retention_instruction' do
      before do
        plate.retention_instruction = :destroy_after_2_years
        plate.custom_metadatum_collection = nil
      end

      it_behaves_like 'retention instruction'
    end
  end

  context 'when rendering a tube rack' do
    let(:current_user) { user }
    let(:rack_barcode) { create(:barcode) }
    let(:tube_rack) { create(:tube_rack, barcode: rack_barcode) }

    let(:locations) { %w[A01 B01 C01] }
    let(:barcodes) { Array.new(num_tubes) { create(:fluidx) } }
    let!(:tubes) do
      Array.new(num_tubes) do |i|
        create(:sample_tube, :in_a_rack, tube_rack: tube_rack, coordinate: locations[i], barcodes: [barcodes[i]])
      end
    end

    before do
      assign(:asset, tube_rack) # sets @widget = Widget.new in the view template
    end

    context 'when the rack contains tubes' do
      let(:num_tubes) { locations.length }

      it 'displays the barcodes for all the tubes' do
        render
        barcodes.each { |instance| expect(rendered).to match(instance.barcode) }
      end

      it 'displays the coordinates for all the tubes' do
        render
        locations.each { |location| expect(rendered).to match(location) }
      end

      it 'displays the number of samples' do
        render
        expect(rendered).to match(tubes.length.to_s)
      end
    end
  end

  context 'when rendering a tube' do
    let(:current_user) { user }

    let(:tube_barcode) { create(:fluidx) }
    let(:tube) { create(:tube, barcodes: [tube_barcode]) }

    before do
      assign(:asset, tube) # sets @widget = Widget.new in the view template
      assign(:aliquots, tube.aliquots.paginate(page: 1))
    end

    context 'when the tube is inside a rack' do
      before { tube.update(racked_tube:) }

      let(:coordinate) { 'A1' }
      let(:racked_tube) { build(:racked_tube, tube_rack:, coordinate:) }

      let(:rack_barcode) { create(:barcode) }
      let(:tube_rack) { create(:tube_rack, barcodes: [rack_barcode]) }

      it 'renders a tube description label' do
        render
        expect(rendered).to match(/Tube/)
      end

      it 'renders the associated tube rack barcode' do
        render
        expect(rendered).to match(tube_rack.primary_barcode.barcode)
      end

      it 'renders the position in the rack' do
        render
        expect(rendered).to match(tube.racked_tube.coordinate)
      end

      it 'renders the tube barcode' do
        render
        expect(rendered).to match(tube.primary_barcode.barcode)
      end
    end

    context 'when the tube is not in a rack' do
      it 'renders a tube description label' do
        render
        expect(rendered).to match(/Tube/)
      end

      it 'does not render the position label' do
        render
        expect(rendered).not_to match(/Position/)
      end
    end
  end
end
