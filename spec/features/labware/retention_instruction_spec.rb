# frozen_string_literal: true

require 'rails_helper'

describe 'Update retention instructions' do
  before { allow(EventFactory).to receive(:record_retention_instruction_updates) }

  shared_examples 'updating retention instruction' do
    it 'updates the retention instruction' do
      select 'Long term storage', from: 'Retention instruction'
      click_button 'Update'
      expect(EventFactory).to have_received(:record_retention_instruction_updates)
      expect(page).to have_content 'Retention Instruction was successfully updated.'
      expect(page).to have_content 'Long term storage'
    end
  end

  context 'when the user is not an admin' do
    let(:user) { create :user }
    let(:asset) { create :plate_with_3_wells, retention_instruction: :destroy_after_2_years }

    before { visit labware_path(asset) }

    it 'does not allow the user to edit the retention instruction' do
      expect(page).to have_no_content 'Edit Retention Instruction'
    end
  end

  context 'when the user is an admin' do
    before do
      login_user(user)
      visit labware_path(asset)
      click_link 'Edit Retention Instruction'
      expect(page).to have_content 'Edit Retention Instruction'
    end

    context 'when retention instruction exists' do
      let(:user) { create :admin }
      let(:asset) { create :plate_with_3_wells, retention_instruction: :destroy_after_2_years }

      it 'does not display the warning message' do
        expect(page).to have_no_content 'This labware does not currently have a retention instruction.'
      end

      it_behaves_like 'updating retention instruction'
    end

    # NB: This scenario will be obsolete (but still valid) after the script in #4095 is run
    context 'when retention instruction exists in custom_metadata table' do
      let(:user) { create :admin }
      let(:asset) { create :plate_with_3_wells, retention_instruction: :destroy_after_2_years }

      before do
        asset.custom_metadatum_collection =
          create :custom_metadatum_collection, metadata: { retention_instruction: 'Return to customer after 2 years' }
        asset.save
      end

      it 'does not display the warning message' do
        expect(page).to have_no_content 'This labware does not currently have a retention instruction.'
      end

      it 'displays the retention instruction in metadata' do
        expect(page).to have_content 'Return to customer after 2 years'
      end

      it_behaves_like 'updating retention instruction'
    end

    context 'when retention instruction does not exist' do
      let(:user) { create :admin }
      let(:asset) { create :plate_with_3_wells, retention_instruction: nil }

      it 'does not have a retention instruction yet' do
        expect(page).to have_content 'This labware does not currently have a retention instruction.'
      end

      it_behaves_like 'updating retention instruction'
    end

    context 'when retention instruction exists for tube' do
      let(:user) { create :admin }
      let(:asset) { create :tube, retention_instruction: :destroy_after_2_years }

      it 'does not display the warning message' do
        expect(page).to have_no_content 'This labware does not currently have a retention instruction.'
      end

      it_behaves_like 'updating retention instruction'
    end
  end
end
