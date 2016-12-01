# frozen_string_literal: true
require 'rails_helper'
require 'pry'

feature 'Batches controller', js: true do

  let(:request_count) { 3 }
  let(:batch) { create :batch, request_count: request_count }
  let(:user)  { create :admin  }


  background do
    batch
    user
  end

  scenario 'reordering requests' do
    login_user user
    visit batch_path(batch)
    click_link('Edit batch')

    request_list = find('#requests_list')
    request_list.should have_css('tr', count: request_count)
    first_request, last_request = *request_list.all('tr')
    last_request.drag_to(first_request)
  end

  # For use in feature tests. Login as either a new user, or an provided user
  #
  # @param [User] user The user to log in as, or nil to create a new user
  # @return [TrueClass] true
  def login_user(user)
    visit login_path
    fill_in 'Username', with: user.login
    fill_in 'Password', with: 'password'
    click_button 'Login'
    true
  end
end
