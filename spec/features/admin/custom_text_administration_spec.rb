# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/administration/custom_text_administration.feature
describe 'Custom text administration' do
  let(:manager) { create(:admin, login: 'xyz1') }
  let!(:foo) do
    create(:custom_text, identifier: 'foo', differential: 99, content_type: 'letters',
                         content: 'Mary had a little lamb')
  end

  before do
    create(:custom_text, identifier: 'bar', differential: 101, content_type: 'digits', content: '3.1418')
    login_user manager
    visit admin_custom_texts_path
  end

  it 'lists the custom texts and shows the details of an entry in the edit form' do
    ['foo', 'bar', '99', '101', 'letters', 'digits', 'Mary had a little lamb', '3.1418'].each do |text|
      expect(page).to have_text(text)
    end

    visit edit_admin_custom_text_path(foo)

    expect(page).to have_text('Custom Text Edit')
    expect(page).to have_field('Custom text identifier', with: 'foo')
    expect(page).to have_field('Custom text differential', with: '99')
    expect(page).to have_field('Custom text content type', with: 'letters')
    expect(page).to have_field('custom_text[content]', with: 'Mary had a little lamb')
  end

  it 'edits an entry' do
    visit edit_admin_custom_text_path(foo)

    fill_in 'Custom text identifier', with: 'wibble'
    fill_in 'Custom text differential', with: '42'
    fill_in 'Custom text content type', with: 'symbols'
    fill_in 'custom_text[content]', with: '!$%&@'
    click_button 'Save Custom text'

    expect(page).to have_text('Details have been updated')
    expect(foo.reload).to have_attributes(
      identifier: 'wibble',
      differential: 42,
      content_type: 'symbols',
      content: '!$%&@'
    )
  end

  it 'adds a new entry' do
    click_link 'Create custom texts'
    expect(page).to have_text('Custom Text Create')

    fill_in 'Custom text identifier', with: 'wibble'
    fill_in 'Custom text differential', with: '42'
    fill_in 'Custom text content type', with: 'symbols'
    fill_in 'custom_text[content]', with: '!%@'
    click_button 'Save Custom text'

    visit admin_custom_texts_path
    expect(page).to have_text('wibble')
    expect(page).to have_text('foo')
    expect(page).to have_text('bar')

    visit edit_admin_custom_text_path(CustomText.find_by!(identifier: 'wibble'))
    expect(page).to have_text('Custom Text Edit')
    expect(page).to have_field('custom_text[content]', with: '!%@')
  end

  it 'deletes an entry' do
    within('tr', text: 'Mary had a little lamb') { click_link '[Delete]' }

    expect(page).to have_text('Custom text deleted')
    expect(page).to have_text('Custom Text')
    %w[bar 101 digits 3.1418].each { |text| expect(page).to have_text(text) }
    expect(page).to have_no_text('Mary had a little lamb')
  end

  # The model currently does no validations
  it 'saves entries with data entry errors without validation' do
    visit edit_admin_custom_text_path(foo)

    fill_in 'Custom text identifier', with: ''
    fill_in 'Custom text differential', with: 'wibble'
    fill_in 'Custom text content type', with: ' letters '
    fill_in 'custom_text[content]', with: ''
    click_button 'Save Custom text'

    expect(page).to have_text('Details have been updated')

    visit edit_admin_custom_text_path(foo)
    expect(page).to have_field('Custom text identifier', with: '')
    expect(page).to have_field('Custom text differential', with: '0')
    expect(page).to have_field('Custom text content type', with: ' letters ')
    expect(page).to have_field('custom_text[content]', with: '')
  end
end
