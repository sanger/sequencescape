# frozen_string_literal: true

require 'rails_helper'

describe 'Create a new tag set' do
  let(:user) { create :admin }
  let(:adapter_type) { create :adapter_type }
  let(:tag_group) { create :tag_group, name: 'test-group-1', adapter_type: }
  let(:tag2_group) { create :tag_group, name: 'test-group-2', adapter_type: }

  before do
    tag_group
    tag2_group
  end

  it 'view tag sets and create a new valid one' do
    login_user user
    visit tag_sets_path
    expect(page).to have_content 'Listing Tag Sets'
    click_on 'Create a new Tag Set'
    expect(page).to have_content 'New Tag Set'
    fill_in('tag_set_name', with: 'Test tag set')
    select(tag_group.name, from: 'Tag Group (i7)')
    select(tag2_group.name, from: 'Tag Group (i5)')
    click_on 'Create tag set'
    expect(page).to have_content 'Tag Set was successfully created.'
    expect(page).to have_content 'Test tag set'
    expect(page).to have_content tag_group.name
    expect(page).to have_content tag2_group.name
    expect(page).to have_content 'Create a new tag layout template from this tag set'
  end

  it 'view tag groups and attempt to create a new one with an existing tag set name' do
    create(:tag_set, name: 'Test tag set')

    login_user user
    visit tag_sets_path
    expect(page).to have_content 'Listing Tag Sets'
    click_on 'Create a new Tag Set'
    expect(page).to have_content 'New Tag Set'
    fill_in('tag_set_name', with: 'Test tag set')
    select(tag_group.name, from: 'Tag Group (i7)')
    select(tag2_group.name, from: 'Tag Group (i5)')
    click_on 'Create tag set'
    expect(page).to have_content 'error prohibited this tag set from being saved'
    expect(page).to have_content 'Name has already been taken'
    fill_in('tag_set_name', with: 'Test tag set 1')
    click_on 'Create tag set'
    expect(page).to have_content 'Tag Set was successfully created.'
    expect(page).to have_content 'Test tag set 1'
    expect(page).to have_content tag_group.name
    expect(page).to have_content tag2_group.name
    expect(page).to have_content 'Create a new tag layout template from this tag set'
  end
end
