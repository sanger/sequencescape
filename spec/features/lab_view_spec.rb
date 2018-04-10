# frozen_string_literal: true

require 'rails_helper'

feature 'Lab view', js: true do
  let(:user) { create :user, email: 'login@example.com' }
  let(:library_tube) { create :library_tube }

  scenario 'User can update concentrations' do
    login_user user
    click_link 'Lab View'
    fill_in('barcode', with: library_tube.machine_barcode)
    click_on 'Find'
    fill_in('Volume (µL)', with: 20)
    fill_in('Concentration (nM)', with: 30)
    click_on 'Update'
    expect(page).to have_text 'Asset was successfully updated'
  end
end
