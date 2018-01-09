require 'rails_helper'

feature 'Primer Panel' do
  let(:user) { create :admin, email: 'login@example.com' }

  scenario 'user can add a new primer panel' do
    login_user user
    click_on 'Admin'
    click_on 'Primer Panel'
    click_on 'New Primer Panel'
    fill_in 'Name', with: 'My Primer panel'
    fill_in 'SNP count', with: 32
    click_on 'Create'
    expect(page).to have_content("Created 'My Primer panel'")
  end
end
