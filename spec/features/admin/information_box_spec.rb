# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/administration/13325113_information_box.feature
describe 'Site wide information box' do
  let(:admin) { create(:admin) }
  let!(:custom_text) do
    # Cucumber relied on db seeds for this record, RSpec has to create it
    create(:custom_text, identifier: 'app_info_box', differential: 1, content_type: 'text/html', content: nil)
  end

  before do
    login_user admin
    visit edit_admin_custom_text_path(custom_text)
  end

  it 'shows the editable fields of the information box custom text' do
    expect(page).to have_text('Custom Text Edit')
    expect(page).to have_field('Custom text identifier', with: 'app_info_box')
    expect(page).to have_field('Custom text differential', with: '1')
    expect(page).to have_field('Custom text content type', with: 'text/html')
  end

  it 'displays a new message on every page' do
    # Use the field name as Capybara allows partial label matches, which would also match the content type field
    fill_in 'custom_text[content]', with: 'Something, something, darkside...'
    click_button 'Save Custom text'

    visit root_path
    expect(page).to have_css('#app-info-box', text: 'Something, something, darkside...')
  end

  it 'hides the information box when the message is blank' do
    fill_in 'custom_text[content]', with: 'A message'
    click_button 'Save Custom text'
    visit edit_admin_custom_text_path(custom_text)

    fill_in 'custom_text[content]', with: ''
    click_button 'Save Custom text'

    visit root_path
    expect(page).to have_css('nav.main-nav')
    expect(page).to have_no_css('#app-info-box')
  end
end
