require 'spec_helper'
RSpec.describe 'labware/show.html.erb', type: :view do
  include AuthenticatedSystem
  let(:user) { create :user }

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
