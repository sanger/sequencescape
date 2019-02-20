# frozen_string_literal: true

require 'rails_helper'

feature 'Manage a study' do
  let(:user) { create :admin }
  let!(:study) { create :study, name: 'Original name' }

  scenario 'Rename a study', js: true do
    login_user(user)
    visit study_path(study)
    click_link 'Manage'
    expect(page).to have_content('Original name')
    fill_in 'Study name', with: 'Updated name'
    click_on 'Update'
    expect(page).to have_content('Updated name')
    expect(page).not_to have_content('Original name')
  end
end
