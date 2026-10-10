# frozen_string_literal: true

require 'rails_helper'

describe 'Add a printer' do
  let(:user) { create(:admin, email: 'login@example.com') }

  before do
    create(:plate_barcode_printer_type)
  end

  it 'user can add a new printer' do
    login_user user
    click_on 'Admin'
    click_on 'Printer management'
    click_on 'Create Barcode Printer'
    fill_in 'Name', with: 'My Printer'
    click_on 'Submit'
    expect(page).to have_text('Barcode Printer was successfully created.')
  end
end
