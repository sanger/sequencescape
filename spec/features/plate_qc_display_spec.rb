require 'rails_helper'

feature 'Plate QC display' do
  let(:user) { create :user, email: 'login@example.com' }

  feature 'with no QC results' do

    let!(:plate) { create(:plate, sample_count: 3)}

    scenario 'displays an empty table' do
      login_user user
      visit plate_path(plate)
      ['concentration', 'volume', 'quantity_in_nano_grams', 'snp_count', 'gel_pass', 'rin'].each do |qc_result|
        within("##{qc_result}") do
          expect(page).to have_selector('td', count: 126)
          expect(page).to have_selector('tr', count: 10)
          expect(page).to have_selector('th[2]', text: '1')
          expect(page).to have_selector('th[13]', text: '12')
          expect(page).to have_selector('tr[1]/td[1]', text: 'A')
          expect(page).to have_selector('tr[8]/td[14]', text: 'H')
          expect(page).to have_selector('tr[9]/td[2]', text: '1')
          expect(page).to have_selector('tr[9]/td[13]', text: '12')
        end
      end
    end
  end

  feature 'with QC results' do

    let!(:plate) do
      plate = create(:plate, sample_count: 3)
      plate.wells.each do |well|
        well.qc_results << [ build(:qc_result_concentration), build(:qc_result_volume), build(:qc_result_snp_count), build(:qc_result_rin) ]
        well.well_attribute.update_attributes!(gel_pass: 'OK')
      end
      plate
    end

    before(:each) do
      login_user user
      visit plate_path(plate)
    end     

    scenario 'displays the correct data' do
      ['concentration', 'volume', 'quantity_in_nano_grams', 'snp_count', 'gel_pass', 'rin'].each do |qc_result|
        within("##{qc_result}") do
          plate.wells.each_with_index do |well, index|
            expect(page).to have_selector("tr[#{1+index}]/td[2]", text: well.qc_result_for(qc_result))
          end
        end
      end
     
    end

  end

end