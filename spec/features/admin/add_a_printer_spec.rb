# frozen_string_literal: true

require 'rails_helper'

describe 'Add a printer' do
  let(:user) { create(:admin, email: 'login@example.com') }

  it 'user can add a new printer' do
    login_user user
    click_on 'Admin'
    click_on 'Printer management'
    click_on 'Create Barcode Printer'
    # fill_in 'Name', with: 'My Primer panel'
    # fill_in 'SNP count', with: 32
    # fill_in 'primer_panel_programs_pcr_1_name', with: 'Pcr 1 Name'
    # fill_in 'primer_panel_programs_pcr_1_duration', with: '90'
    # fill_in 'primer_panel_programs_pcr_2_name', with: 'Pcr 2 Name'
    # fill_in 'primer_panel_programs_pcr_2_duration', with: '120'
    # click_on 'Create'
    # expect(page).to have_content("Created 'My Primer panel'")
  end
end
