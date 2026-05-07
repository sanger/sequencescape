# frozen_string_literal: true

require 'rails_helper'

describe 'Create a new tag group' do
  let(:user) { create(:admin) }

  before { create(:adapter_type, name: 'My type') }

  it 'view tag groups and create a new valid one' do
    login_user user
    visit tag_groups_path
    expect(page).to have_text 'Listing Tag Groups'
    click_on 'Create a new Tag Group'
    expect(page).to have_text 'New Tag Group'
    fill_in('tag_group_name', with: 'Test tag group')
    fill_in('tag_group_oligos_text', with: 'ACTGGTCA GGTTCCAA')
    select('My type', from: 'Adapter Type')
    click_on 'Create tag group'
    expect(page).to have_text 'Tag Group was successfully created.'
    expect(page).to have_text 'ACTGGTCA'
    expect(page).to have_text 'GGTTCCAA'
    expect(page).to have_text 'My type'
    expect(page).to have_text 'Create a new tag layout template from this tag group'
  end

  it 'view tag groups and attempt to create a new one with invalid oligos' do
    login_user user
    visit tag_groups_path
    expect(page).to have_text 'Listing Tag Groups'
    click_on 'Create a new Tag Group'
    expect(page).to have_text 'New Tag Group'
    fill_in('tag_group_name', with: 'Test tag group')
    fill_in('tag_group_oligos_text', with: 'ACTGGTCA INVALID')
    click_on 'Create tag group'
    expect(page).to have_text '2 errors prohibited this tag group from being saved'
    fill_in('tag_group_oligos_text', with: 'ACTGGTCA GGTTCCAA')
    click_on 'Create tag group'
    expect(page).to have_text 'Tag Group was successfully created.'
    expect(page).to have_text 'ACTGGTCA'
    expect(page).to have_text 'GGTTCCAA'
    expect(page).to have_text 'Create a new tag layout template from this tag group'
  end
end
