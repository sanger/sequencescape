# frozen_string_literal: true

require 'rails_helper'

describe 'Lab view', :js do
  let(:user) { create(:user, email: 'login@example.com') }
  let(:library_tube) { create(:library_tube) }

  it 'User can update concentrations' do
    login_user user
    click_link 'Lab View'
    fill_in('barcode', with: library_tube.machine_barcode)
    click_on 'Find'
    fill_in('Volume (µL)', with: 20)
    fill_in('Concentration (nM)', with: 30)
    click_on 'Update'
    expect(page).to have_text 'Labware was successfully updated'
    expect(find_field('Volume (µL)').value).to eq('20.0')
    expect(find_field('Concentration (nM)').value).to eq('30.0')
  end
end
