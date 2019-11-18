require 'spec_helper'
RSpec.describe 'labware/show.html.erb', type: :view do
  include AuthenticatedSystem
  let(:user) { create :user }

  context 'when rendering a tube rack' do
    let(:current_user) { user }
    let(:rack_barcode) { create :barcode }
    let(:tube_rack) { create :tube_rack, barcode: rack_barcode }

    let(:locations) { TokenUtilsLims.generate_positions(('A'..'H').to_a, (1..12).to_a)}
    let(:barcodes) { num_tubes.times.map{ create :fluidx }}
    let(:tubes) {
      num_tubes.times.map do |i|
        create(:tube, :in_a_rack, {
          tube_rack: tube_rack, coordinate: locations[i], barcodes: [barcodes[i]]
        })
      end
    }
    before do
      assign(:asset, tube_rack)  # sets @widget = Widget.new in the view template
    end
    context 'when the rack is totally occupied' do
      let(:num_tubes) { locations.length }
      it 'displays the barcodes of all the tubes' do
        render
        barcodes.each do |instance|
          expect(rendered).to match(instance.barcode)
        end
      end
    end
    context 'when the rack is partially occupied' do
      let(:num_tubes) { (locations.length / 2).to_i }
      it 'displays the barcodes of part of the tubes' do
        render
        barcodes[0..num_tubes].each do |instance|
          expect(rendered).to match(instance.barcode)
        end
      end
    end
    context 'when the rack is empty' do
      let(:num_tubes) { 0 }
    end
  end

  context 'when rendering a tube' do
    let(:current_user) { user }

    let(:tube_barcode) { create :fluidx }
    let(:tube) { create :tube, barcodes: [tube_barcode] }

    before do
      assign(:asset, tube)  # sets @widget = Widget.new in the view template
    end

    context 'when the tube is inside a rack' do
      before do
        tube.update_attributes(racked_tube: racked_tube)
      end
      let(:coordinate) { 'A1' }
      let(:racked_tube) { build :racked_tube, tube_rack: tube_rack, coordinate: coordinate}

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
