# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/administration/robots.feature
describe 'Manage robots' do
  let(:admin) { create(:admin) }

  it 'adds a new robot with a property' do
    login_user admin
    visit admin_path
    expect(page).to have_text('Administration')
    click_link 'Robot management'

    click_link 'New robot'
    expect(page).to have_text('New robot')
    fill_in 'Name', with: 'A robot'
    fill_in 'Location', with: 'A lab'
    click_button 'Create'
    expect(page).to have_text('Robot was successfully created')

    click_link 'Manage Properties'
    click_link 'New property'
    within('#new_robot_property') do
      fill_in 'Name', with: 'SCR1'
      fill_in 'Value', with: '123'
      # The last text field of the form is the property's bed identifier
      all('input[type="text"]').last.set('bed_1')
      click_button 'Create'
    end
    expect(page).to have_text('SCR1')

    click_link 'Back to Robot'
    expect(page).to have_text('SCR1')
    expect(page).to have_text('A robot')

    click_link 'All robots'
    expect(page).to have_text('A robot')
  end
end
