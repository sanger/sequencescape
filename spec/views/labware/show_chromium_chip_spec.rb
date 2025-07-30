# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'labware/show.html.erb' do
  include AuthenticatedSystem

  let(:user) { create(:user) }

  context 'when rendering a Chromium Chip 16-well plate' do
    # We have a plate with a purpose that has an asset_shape of Shape4x1
    # and a size of 16. The plate has 16 wells, each with a sample. It has
    # transfer requests into the plate in passed state, and a parent plate.

    let(:current_user) { user }
    let(:purpose_name) { 'chromium-chip-purpose' }
    let(:purpose) { create(:shape4x1_purpose, name: purpose_name) } # AssetShape Shape4x1, size 16
    let(:plate) { create(:child_plate, well_factory: :passed_well, purpose: purpose, size: 16, sample_count: 16) }
    let(:doc) { Nokogiri.HTML(rendered) }

    before do
      assign(:asset, plate)
      render
    end

    it 'displays the barcode of the plate' do
      expect(rendered).to have_css('tr', text: /Human barcode\s*#{plate.human_barcode}/) # Human Barcode
    end

    it 'displays the purpose of the plate' do
      expect(rendered).to have_css('tr', text: /Purpose\s*#{purpose_name}/) # Purpose chromium-chip-purpose
    end

    it 'displays the plate wells' do
      # The first column of the Samples table (Well)
      expect(rendered).to have_table('plate-samples-table')

      table = doc.at('table#plate-samples-table')
      column_texts = table.search('tr').filter_map { |tr| tr.at('td:first-child')&.text }

      expected = %w[A1 B1 A2 B2 A3 B3 A4 B4 A5 B5 A6 B6 A7 B7 A8 B8] # Full Chromium Chip 16-well plate
      expect(column_texts).to eq(expected)
    end

    it 'displays the plate samples' do
      # The second column of the Samples table (Sample Name)
      expect(rendered).to have_table('plate-samples-table')

      table = doc.at('table#plate-samples-table')
      column_texts = table.search('tr').filter_map { |tr| tr.at('td:nth-child(2)')&.text }

      expected = plate.wells_in_column_order.map { |w| w.aliquots.first.sample.name } # Samples in wells in column order
      expect(column_texts).to eq(expected)
    end

    it 'displays the parent relationship' do
      # The first row of the Relations table  [Asset, Relationship type]
      expect(rendered).to have_table('relations-table')

      table = doc.at('table#relations-table')

      asset_text = table.at('tbody tr').at('td')&.text
      expect(asset_text).to eq("Plate: #{plate.parents.first.name}") # Plate

      relationship_type_text = table.at('tbody tr').at('td:nth-child(2)')&.text
      expect(relationship_type_text).to eq('Parent') # Relationship
    end

    it 'displays requests into the plate' do
      expect(rendered).to have_table('target-requests-table')

      table = doc.at('table#target-requests-table')
      number_of_rows = table.search('tbody tr').size

      expect(number_of_rows).to eq(plate.requests_as_target.size) # Number of requests

      column_texts = table.at('tbody tr').search('td').map { |td| td.text.strip } # First request

      expect(column_texts[0]).to eq(plate.wells.first.requests_as_target.first.id.to_s) # request id
      expect(column_texts[1]).to eq(plate.wells.first.requests_as_target.first.request_type.name) # request type
      expect(column_texts[2]).to eq("Study: #{plate.studies.first.name}") # study
      expect(column_texts[3]).to eq('PASSED') # request status
    end
  end
end
