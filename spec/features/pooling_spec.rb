require 'rails_helper'

feature 'Pooling', js: true do
  let(:user) { create :user, email: 'login@example.com' }

  feature 'from page directly' do
    let!(:empty_lb_tube1) { create :empty_library_tube, barcode: 1 }
    let!(:empty_lb_tube2) { create :empty_library_tube, barcode: 2 }
    let!(:untagged_lb_tube1) { create :library_tube, barcode: 3 }
    let!(:untagged_lb_tube2) { create :library_tube, barcode: 4 }
    let!(:tagged_lb_tube1) { create :tagged_library_tube, barcode: 5 }
    let!(:tagged_lb_tube2) { create :tagged_library_tube, barcode: 6 }

    scenario 'user can pool from different tubes to stock and standard mx tubes' do
      login_user user
      visit new_pooling_path
      expect(page).to have_content 'Scan tube'
      click_on 'Transfer'
      expect(page).to have_content 'Source assets were not scanned or were not found in sequencescape'
      fill_in('asset_scan', with: '1234567890123')
      within('.barcode_list') do
        expect(page).to have_content '1234567890123'
      end
      fill_in('asset_scan', with: (empty_lb_tube1.ean13_barcode).to_s)
      fill_in('asset_scan', with: (empty_lb_tube2.ean13_barcode).to_s)
      fill_in('asset_scan', with: (untagged_lb_tube1.ean13_barcode).to_s)
      fill_in('asset_scan', with: (untagged_lb_tube2.ean13_barcode).to_s)
      click_on 'Transfer'
      expect(page).to have_content 'Source assets with barcode(s) 1234567890123 were not found in sequencescape'
      expect(page).to have_content "Source assets with barcode(s) #{empty_lb_tube1.ean13_barcode}, #{empty_lb_tube2.ean13_barcode} do not have any aliquots"
      expect(page).to have_content 'Same tags are used on rows 3, 4.'
      first('a', text: 'Remove from list').click
      first('a', text: 'Remove from list').click
      first('a', text: 'Remove from list').click
      first('a', text: 'Remove from list').click
      expect(page).to have_content 'Scanned: 1'
      fill_in('asset_scan', with: (tagged_lb_tube1.ean13_barcode).to_s)
      fill_in('asset_scan', with: (tagged_lb_tube2.ean13_barcode).to_s)
      check 'Create stock multiplexed tube'
      click_on 'Transfer'
      expect(page).to have_content 'Samples were transferred successfully'
    end
  end

  feature 'from sample manifest page' do
    let!(:sample_manifest) { create :tube_sample_manifest_with_several_tubes, asset_type: 'library' }

    background do
      sample_manifest.generate
      aliquot = Tube.last.aliquots.first
      aliquot.tag = create :tag
      aliquot.save
    end

    scenario 'user can pool from different tubes to stock and standard mx tubes' do
      login_user user
      visit sample_manifest_path(sample_manifest.id)
      click_on 'Pool'
      expect(page).to have_content 'Scan tube'
      expect(page).to have_content 'Scanned: 5'
      first('a', text: 'Remove from list').click
      first('a', text: 'Remove from list').click
      first('a', text: 'Remove from list').click
      click_on 'Transfer'
      expect(page).to have_content 'Samples were transferred successfully'
    end
  end
end
