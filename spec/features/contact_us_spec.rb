# frozen_string_literal: true
require 'rails_helper'

feature 'Contact us' do

  let(:user) { create :user }

  scenario 'user contact us if something is wrong' do
    login_user user
    visit root_path
    click_link 'contact us'
    expect(page).to have_content('Please, fill in this form')
    click_button('Send')
    expect(page).to have_content("User name can't be blank")
    fill_in("Name", with: "John")
    fill_in("What were you trying to do?", with: "Do some stuff")
    fill_in("What has happened?", with: "Something went wrong")
    fill_in("What did you expect to happen?", with: "Sqsc to work")
    click_button('Send')
    expect(page).to have_content('Thank you for your request. We will contact you shortly')
  end

  def login_user(user)
    visit login_path
    fill_in 'Username', with: user.login
    fill_in 'Password', with: 'password'
    click_button 'Login'
    true
  end
end