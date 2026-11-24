# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/sample_manifest/supplier.feature
describe 'Managing sample suppliers' do
  let(:user) { create(:user) }

  before do
    login_user user
    visit('/sdb/')
  end

  it 'creates a supplier' do
    click_link('Create supplier')
    expect(page).to have_text('New Supplier')
    fill_in('Name', with: 'Test supplier name')
    fill_in('Address', with: 'WTSI, Cambridge, UK')
    fill_in('Contact name', with: 'John Doe')
    fill_in('Email', with: 'test@example.com')
    fill_in('Phone number', with: '1234567')
    click_button('Create Supplier')
    expect(page).to have_text('Supplier was successfully created')
    expect(page).to have_current_path('/sdb/')
    click_link('View all suppliers')
    expect(page).to have_text('Test supplier name')
    expect(page).to have_text('John Doe')
  end

  it 'edits an existing supplier' do
    create(:supplier, name: 'Test supplier name')
    click_link('View all suppliers')
    click_link('Test supplier name')
    click_link('Edit')
    fill_in('Name', with: 'New supplier name')
    click_button('Update Supplier')
    expect(page).to have_text('Supplier was successfully updated')
    expect(page).to have_text('New supplier name')
  end
end
