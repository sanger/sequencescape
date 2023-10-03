# frozen_string_literal: true

require 'rails_helper'

describe 'Create a new tag layout template' do
  let(:user) { create :admin }
  let(:tag_group_1) { create(:tag_group_with_tags, name: 'Test tag group 1') }
  let(:tag_group_2) { create(:tag_group_with_tags, name: 'Test tag group 2') }

  before do
    tag_group_1
    tag_group_2
  end

  it 'create a new layout template from a tag group', :js do
    login_user user
    visit tag_group_path(tag_group_1)
    expect(page).to have_content 'Test tag group 1'
    click_on 'Create a new tag layout template from this tag group'
    expect(page).to have_content 'Tag Layout Template New'
    within('#new_tag_layout_template') do
      fill_in('tag_layout_template_name', with: 'Test tag layout template')
      select('InColumns (A1,B1,C1...)', from: 'tag_layout_template_direction_algorithm')
      click_on 'Create tag layout template'
    end
    expect(page).to have_content 'The Tag Layout Template has been successfully created.'
    expect(page).to have_content 'Name: Test tag layout template'
    expect(page).to have_content "Tag Group: #{tag_group_1.name}"
    expect(page).to have_content 'Tag2 Group: na'
    expect(page).to have_content 'Direction the tags are laid out by: column'
    expect(page).to have_content 'Walking by: wells of plate'
    expect(page).to have_content 'To tag layout templates list'
  end

  it 'create a new layout template directly', :js do
    login_user user
    visit new_tag_layout_template_path
    expect(page).to have_content 'Tag Layout Template New'
    within('#new_tag_layout_template') do
      fill_in('tag_layout_template_name', with: 'Test tag layout template')
      select(tag_group_1.name, from: 'tag_layout_template_tag_group_id')
      select(tag_group_2.name, from: 'tag_layout_template_tag2_group_id')
      select('InColumns (A1,B1,C1...)', from: 'tag_layout_template_direction_algorithm')
      click_on 'Create tag layout template'
    end
    expect(page).to have_content 'The Tag Layout Template has been successfully created.'
    expect(page).to have_content 'Name: Test tag layout template'
    expect(page).to have_content "Tag Group: #{tag_group_1.name}"
    expect(page).to have_content "Tag2 Group: #{tag_group_2.name}"
    expect(page).to have_content 'Direction the tags are laid out by: column'
    expect(page).to have_content 'Walking by: wells of plate'
    expect(page).to have_content 'To tag layout templates list'
  end

  it 'get an error when creating a new layout template', :js do
    login_user user
    visit new_tag_layout_template_path
    expect(page).to have_content 'Tag Layout Template New'

    within('#new_tag_layout_template') do
      fill_in('tag_layout_template_name', with: 'Test tag layout template')
      select('InColumns (A1,B1,C1...)', from: 'tag_layout_template_direction_algorithm')
      click_on 'Create tag layout template'
    end

    expect(page).to have_content 'error prohibited this tag layout template from being saved'
    expect(page).to have_content 'Tag group must exist'
  end
end
