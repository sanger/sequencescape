# frozen_string_literal: true
require 'rails_helper'
require 'pry'

feature 'Studies controller' do
  let(:user) { create :admin }

  scenario 'managed can be created with an hmdmc number', js: true do
    login_user user
    visit new_study_path
    select("Open (ENA)", from: "study_study_metadata_attributes_data_release_strategy")
    expect(page).not_to have_content('HMDMC approval number')
    select("Managed (EGA)", from: "study_study_metadata_attributes_data_release_strategy")
    expect(page).to have_content('HMDMC approval number')
    click_button 'Create'
    expect(page).not_to have_content "Study metadata hmdmc approval number can't be blank"
  end

  def login_user(user)
    visit login_path
    fill_in 'Username', with: user.login
    fill_in 'Password', with: 'password'
    click_button 'Login'
    true
  end
end
