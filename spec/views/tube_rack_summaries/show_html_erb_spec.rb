# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'tube_rack_summaries/show.html.erb' do
  include AuthenticatedSystem

  let(:user) { create(:user) }

  context 'when rendering a tube rack summary' do
    let(:current_user) { user }
    let(:rack_barcode) { create(:barcode) }
    let(:tube_rack) { create(:tube_rack, barcode: rack_barcode) }

    let(:locations) { %w[A01 B01 C01] }
    let(:barcodes) { Array.new(num_tubes) { create(:fluidx) } }

    before do
      Array.new(num_tubes) do |i|
        create(:sample_tube, :in_a_rack, tube_rack: tube_rack, coordinate: locations[i], barcodes: [barcodes[i]])
      end

      assign(:tube_rack, tube_rack) # sets @widget = Widget.new in the view template
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
    end
  end
end
