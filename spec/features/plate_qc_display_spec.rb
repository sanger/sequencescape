# frozen_string_literal: true

require 'rails_helper'

describe 'Plate QC display' do
  let(:user) { create(:user, email: 'login@example.com') }
  let(:well_count) { 3 }

  describe 'with no QC results' do
    let!(:plate) { create(:plate, well_count:) }

    it 'displays an empty table' do
      login_user user
      visit plate_path(plate)
      %w[concentration volume quantity_in_nano_grams loci_passed rin].each do |qc_result|
        within("##{qc_result}") do
          expect(page).to have_css('td', count: 126)
          expect(page).to have_css('tr', count: 10)
          expect(page).to have_css('th[2]', text: '1')
          expect(page).to have_css('th[13]', text: '12')
          expect(page).to have_css('tr[1]/td[1]', text: 'A')
          expect(page).to have_css('tr[8]/td[14]', text: 'H')
          expect(page).to have_css('tr[9]/td[2]', text: '1')
          expect(page).to have_css('tr[9]/td[13]', text: '12')
        end
      end
    end
  end

  describe 'with QC results' do
    let!(:plate) do
      plate = create(:plate, well_count:)
      plate.wells.each do |well|
        well.qc_results << [
          build(:qc_result_concentration),
          build(:qc_result_volume),
          build(:qc_result_loci_passed),
          build(:qc_result_rin)
        ]
      end
      plate
    end

    before do
      login_user user
      visit plate_path(plate)
    end

    it 'displays the correct data' do
      %w[concentration volume quantity_in_nano_grams loci_passed rin].each do |qc_result|
        within("##{qc_result}") do
          plate.wells.each_with_index do |well, index|
            expect(page).to have_css("tr[#{1 + index}]/td[2]", text: well.qc_result_for(qc_result))
          end
        end
      end
    end
  end
end
