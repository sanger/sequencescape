# frozen_string_literal: true

require 'rails_helper'

describe 'Update retention instructions' do

  shared_examples 'updating retention instruction' do
    it 'updates the retention instruction' do
      select 'Long term storage', from: 'Retention instruction'
      click_button 'Update'
      expect(page).to have_content 'Labware was successfully updated.'
      expect(page).to have_content 'Long term storage'
    end
  end

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
      expect(page).to have_no_content 'This asset does not currently have a retention instruction.'
    end

    it_behaves_like 'updating retention instruction'
  end

  context 'when retention instruction does not exist' do
    let(:user) { create :admin }
    let(:asset) { create :plate_with_3_wells, retention_instruction: nil }

    it "does not have a retention instruction yet" do
      expect(page).to have_content 'This asset does not currently have a retention instruction.'
    end

    it_behaves_like 'updating retention instruction'
  end

end