# frozen_string_literal: true

require 'rails_helper'

describe 'Labwhere reception', js: true do
  let(:user) { create :user, email: 'login@example.com', swipecard_code: 12_345 }
  let(:plate) { create :plate }

  it 'user can scan plates into the reception' do
    login_user user
    visit labwhere_receptions_path
    expect(page).to have_content 'Labwhere Reception'
    fill_in('User barcode or swipecard', with: 12_345)
    click_on 'Update locations'
    expect(page).to have_content "Asset barcodes can't be blank"
    within('#new_labwhere_reception') do
      fill_in('asset_scan', with: plate.human_barcode).send_keys(:return)
      expect(find('.barcode_list')).to have_content plate.human_barcode
      expect(page).to have_content 'Scanned: 1'
      fill_in('asset_scan', with: 'TEST222').send_keys(:return)
      fill_in('asset_scan', with: 'TEST333').send_keys(:return)
      fill_in('asset_scan', with: 'TEST222').send_keys(:return)
      expect(page).to have_content('TEST222', count: 1)
      expect(page).to have_content 'Scanned: 3'
      first('a', text: 'Remove from list').click
      first('a', text: 'Remove from list').click
      expect(page).to have_content 'Scanned: 1'
      first('a', text: 'Remove from list').click
      fill_in('asset_scan', with: plate.human_barcode).send_keys(:return)
      click_on 'Update locations'
    end
    expect(page).to have_content plate.human_barcode
    expect(page).to have_content plate.purpose.name
    expect(page).to have_link plate.name, href: labware_path(plate)
  end
end
