# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'labware/show.html.erb', type: :view do
  include AuthenticatedSystem
  let(:user) { create :user }

  context 'when rendering a plate' do
    let(:current_user) { user }
    let(:plate) { create :plate_with_3_wells }

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
  end

  context 'when rendering a tube rack' do
    let(:current_user) { user }
    let(:rack_barcode) { create :barcode }
    let(:tube_rack) { create :tube_rack, barcode: rack_barcode }

    let(:locations) { %w[A01 B01 C01] }
    let(:barcodes) { Array.new(num_tubes) { create :fluidx } }
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

    let(:tube_barcode) { create :fluidx }
    let(:tube) { create :tube, barcodes: [tube_barcode] }

    before do
      assign(:asset, tube) # sets @widget = Widget.new in the view template
      assign(:aliquots, tube.aliquots.paginate(page: 1))
    end

    context 'when the tube is inside a rack' do
      before { tube.update(racked_tube: racked_tube) }

      let(:coordinate) { 'A1' }
      let(:racked_tube) { build :racked_tube, tube_rack: tube_rack, coordinate: coordinate }

      let(:rack_barcode) { create :barcode }
      let(:tube_rack) { create :tube_rack, barcodes: [rack_barcode] }

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
