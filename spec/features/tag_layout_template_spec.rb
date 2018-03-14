# frozen_string_literal: true

require 'rails_helper'

feature 'Create a new tag layout template' do
  let(:user) { create :admin }

  scenario 'create a new layout template from a tag group', js: true do
    login_user user
    visit tag_groups_path
    expect(page).to have_content 'Listing Tag Groups'
    click_on 'Create a new Tag Group'
    expect(page).to have_content 'New Tag Group'
    fill_in('tag_group_name', with: 'Test tag group')
    fill_in('tag_group_oligos_text', with: 'ACTGGTCA GGTTCCAA')
    click_on 'Create tag group'
    expect(page).to have_content 'Tag Group was successfully created.'
    click_on 'Create tag layout template'
    expect(page).to have_content '?' # TODO: new tag layout page
    # TODO: fill in options and click create
  end
end
