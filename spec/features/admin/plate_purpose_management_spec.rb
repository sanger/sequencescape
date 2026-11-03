# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/administration/plate_purpose.feature
describe 'Manage plate purposes' do
  let(:admin) { create(:admin) }

  before do
    create(:plate_purpose, name: 'Stock Plate')
    login_user admin
    visit admin_plate_purposes_path
  end

  it 'lists the existing plate purposes' do
    expect(page).to have_text('Plate Purposes')
    expect(page).to have_text('Stock Plate')
  end

  it 'adds and renames a plate purpose' do
    click_link 'New Plate Purpose'
    fill_in 'Name', with: 'A new plate purpose'
    click_button 'Create'
    expect(page).to have_text('Plate Purpose was successfully created')
    expect(page).to have_current_path(admin_plate_purposes_path)
    expect(page).to have_text('A new plate purpose')

    click_link 'Edit A new plate purpose'
    expect(page).to have_text('Editing Plate Purpose')
    fill_in 'Name', with: 'Renamed plate purpose'
    click_button 'Update'

    expect(page).to have_text('Plate Purpose was successfully updated')
    expect(page).to have_current_path(admin_plate_purposes_path)
    expect(page).to have_text('Renamed plate purpose')
    expect(page).to have_no_text('A new plate purpose')
  end

  [['a space at the end', 'ABC   '], ['a space at the beginning', '   ABC']].each do |description, name|
    it "rejects a name with #{description}" do
      click_link 'New Plate Purpose'
      fill_in 'Name', with: name
      click_button 'Create'

      expect(page).to have_text('Name is invalid')
    end
  end
end
