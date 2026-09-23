# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Managing a study' do
  let!(:study) { create(:study, name: 'Study B') }

  context 'when a regular user views a study' do
    let(:user) { create(:user) }

    it 'does not show the Manage link' do
      login_user(user)
      visit study_path(study)

      within('aside') do
        expect(page).to have_no_link('Manage')
      end
    end
  end

  context 'when an administrator manages study properties' do
    let(:user) { create(:admin) }

    before do
      login_user(user)
      visit study_path(study)
      click_link 'Manage'
    end

    it 'updates the HuMFre approval number' do
      expect(page).to have_text('Manage Study Study B')
      expect(page).to have_field('HMDMC approved', disabled: true)
      expect(page).to have_field('HuMFre approval number')

      fill_in 'HuMFre approval number', with: 'XX/XXX'
      click_button 'Update'

      expect(page).to have_text('Your study has been updated')
      expect(page).to have_field('HuMFre approval number', with: 'XX/XXX')

      click_button 'Update'
      expect(page).to have_text('Your study has been updated')
    end
  end

  context 'when a data access coordinator manages study properties' do
    let(:user) { create(:data_access_coordinator) }

    before do
      user.grant_administrator
      login_user(user)
      visit study_path(study)
      click_link 'Manage'
    end

    it 'updates the HMDMC approval status' do
      expect(page).to have_text('Manage Study Study B')
      hmdmc_field = find_field('HMDMC approved')
      expect(hmdmc_field).not_to be_disabled
      expect(hmdmc_field).not_to be_checked

      check 'HMDMC approved'
      click_button 'Update'

      expect(page).to have_text('Your study has been updated')
      expect(page).to have_field('HMDMC approved', checked: true)

      click_button 'Update'
      expect(page).to have_text('Your study has been updated')
    end
  end

  context 'when an administrator manages ethical approval documents' do
    let(:user) { create(:admin) }

    before do
      login_user(user)
      visit study_information_path(study)
      click_link 'Manage'
    end

    it 'uploads and deletes ethical approval documents' do
      attach_file('study_uploaded_data', Rails.root.join('test/data/blah.fasta'))
      click_button 'Update'

      expect(page).to have_text('Your study has been updated')
      expect(page).to have_text('Listing 1 document')
      expect(page).to have_text('blah.fasta')

      attach_file('study_uploaded_data', Rails.root.join('test/data/very_small_file'))
      click_button 'Update'

      expect(page).to have_text('Your study has been updated')
      expect(page).to have_text('Listing 2 documents')
      expect(page).to have_text('very_small_file')

      click_link 'Delete very_small_file'

      expect(page).to have_text('Document was successfully deleted')
      expect(page).to have_text('Listing 1 document')
      expect(page).to have_text('blah.fasta')
      expect(page).to have_no_text('very_small_file')
    end
  end
end
