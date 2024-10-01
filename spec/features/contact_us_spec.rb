# frozen_string_literal: true

require 'rails_helper'

describe 'Contact us' do
  let(:user) { create :user, email: 'login@example.com' }

  it 'user can request help via Fresh Service' do
    login_user user
    visit root_path
    expect(page).to have_link('Help', href: configatron.fresh_sevice_new_ticket_url)
  end
end
