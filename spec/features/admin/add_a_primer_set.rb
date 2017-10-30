require 'rails_helper'

feature 'Primer Set' do
  let(:user) { create :admin, email: 'login@example.com' }

  scenario 'user can add a new primer set' do
    login_user user
    click_on 'Admin'
    click_on 'Primer Sets'
    click_on 'New Primer Set'
    fill_in 'Name', with: 'My Primer set'
    fill_in 'SNP count', with: 32
    click_on 'Create'
    expect(page).to have_content("Created 'My Primer set'")
  end
end
