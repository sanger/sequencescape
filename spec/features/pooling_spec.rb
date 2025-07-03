# frozen_string_literal: true

require 'rails_helper'

describe 'Pooling', :js, :poolings do
  let(:user) { create(:user, email: 'login@example.com') }

  describe 'from page directly' do
    let!(:empty_lb_tube1) { create(:empty_library_tube, barcode: 1) }
    let!(:empty_lb_tube2) { create(:empty_library_tube, barcode: 2) }
    let!(:untagged_lb_tube1) { create(:library_tube, barcode: 3) }
    let(:sample1) { untagged_lb_tube1.samples.first }
    let!(:untagged_lb_tube2) { create(:library_tube, barcode: 4) }
    let(:sample2) { untagged_lb_tube2.samples.first }
    let!(:tagged_lb_tube1) { create(:tagged_library_tube, barcode: 5) }
    let!(:tagged_lb_tube2) { create(:tagged_library_tube, barcode: 6) }

    it 'user can pool from different tubes to stock and standard mx tubes' do
      login_user user
      visit new_pooling_path
      expect(page).to have_content 'Scan tube'
      click_on 'Transfer'
      expect(page).to have_content 'Source assets were not scanned or were not found in Sequencescape'
      fill_in('asset_scan', with: '1234567890123').send_keys(:return)
      expect(find('.barcode_list')).to have_content '1234567890123'
      fill_in('asset_scan', with: empty_lb_tube1.ean13_barcode.to_s).send_keys(:return)
      fill_in('asset_scan', with: empty_lb_tube2.ean13_barcode.to_s).send_keys(:return)
      fill_in('asset_scan', with: untagged_lb_tube1.ean13_barcode.to_s).send_keys(:return)
      fill_in('asset_scan', with: untagged_lb_tube2.ean13_barcode.to_s).send_keys(:return)
      click_on 'Transfer'

      expect(page).to have_content 'Source assets with barcode(s) 1234567890123 were not found in Sequencescape'
      expect(
        page
        # rubocop:todo Layout/LineLength
      ).to have_content "Source assets with barcode(s) #{empty_lb_tube1.ean13_barcode}, #{empty_lb_tube2.ean13_barcode} do not have any aliquots"

      # rubocop:enable Layout/LineLength
      expect(page).to have_content 'i7 - i5 -', normalize_ws: true
      expect(
        page
        # rubocop:todo Layout/LineLength
      ).to have_content "Sample #{sample1.friendly_name} Library #{untagged_lb_tube1.external_identifier} Scanned Tube #{untagged_lb_tube1.human_barcode}",
                        # rubocop:enable Layout/LineLength
                        normalize_ws: true
      expect(
        page
        # rubocop:todo Layout/LineLength
      ).to have_content "Sample #{sample2.friendly_name} Library #{untagged_lb_tube2.external_identifier} Scanned Tube #{untagged_lb_tube2.human_barcode}",
                        # rubocop:enable Layout/LineLength
                        normalize_ws: true
      first('a', text: 'Remove from list').click
      first('a', text: 'Remove from list').click
      first('a', text: 'Remove from list').click
      first('a', text: 'Remove from list').click
      expect(page).to have_content 'Scanned: 1'
      fill_in('asset_scan', with: tagged_lb_tube1.ean13_barcode.to_s).send_keys(:return)
      fill_in('asset_scan', with: tagged_lb_tube2.ean13_barcode.to_s).send_keys(:return)
      check 'Create stock multiplexed tube'
      click_on 'Transfer'
      expect(page).to have_content 'Samples were transferred successfully'
    end
  end

  describe 'from sample manifest page' do
    let!(:sample_manifest) { create(:tube_sample_manifest_with_sample_tubes, asset_type: 'library') }

    before do
      aliquot = Tube.last.aliquots.first
      aliquot.tag = create :tag
      aliquot.save
    end

    it 'user can pool from different tubes to stock and standard mx tubes' do
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
