# frozen_string_literal: true
require 'rails_helper'

feature 'Contact us' do
  let(:user) { create :user, email: 'login@example.com' }

  scenario 'user can ask for help' do
    number_of_mails = ActionMailer::Base.deliveries.count
    login_user user
    visit root_path
    click_link 'HELP'
    expect(page).to have_content('Please, fill in this form')
    expect(find_field('Your email').value).to eq 'login@example.com'
    expect(find('#user_query_url', visible: false).value).to eq 'http://www.example.com/'
    fill_in('Your email', with: ' ')
    click_button('Send')
    expect(page).to have_content("User email can't be blank")
    expect(find('#user_query_url', visible: false).value).to eq 'http://www.example.com/'
    fill_in('Your email', with: 'new_email@example.com')
    fill_in('What were you trying to do?', with: 'Do some stuff')
    fill_in('What has happened?', with: 'Something went wrong')
    fill_in('What did you expect to happen?', with: 'Sqsc to work')
    click_button('Send')
    expect(ActionMailer::Base.deliveries.count).to eq number_of_mails + 1
    expect(page).to have_content('Thank you for your request. We will contact you shortly (via new_email@example.com)')
  end
end
