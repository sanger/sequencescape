# frozen_string_literal: true

require 'rails_helper'

describe 'Create printers' do
  let(:user) { create(:admin, email: 'login@example.com') }

  it 'can create a new printer' do
    create(:barcode_printer_type)
    configatron.register_printers_automatically = true
    allow(RestClient).to receive(:get).with(
      'http://localhost:9292/v2/printers?filter[name]=yetanotherprinter',
      content_type: 'application/vnd.api+json',
      accept: 'application/vnd.api+json'
    ).and_return('{"data":[]}')
    allow(RestClient).to receive(:post).with(
      'http://localhost:9292/v2/printers',
      { 'data' => { 'attributes' => { 'name' => 'yetanotherprinter', 'printer_type' => 'squix' } } }.to_json,
      content_type: 'application/vnd.api+json',
      accept: 'application/vnd.api+json'
    ).and_return(201)
    login_user user
    visit admin_path
    click_link 'Printer management'
    expect(page).to have_content('Barcode Printers')
    click_link 'Create Barcode Printer'
    fill_in('Name', with: 'yetanotherprinter')
    check('Active')
    choose('squix')
    click_button('Submit')
    expect(page).to have_content('Barcode Printer was successfully created.')
    expect(page).to have_content('yetanotherprinter')
    configatron.register_printers_automatically = false
  end
end
