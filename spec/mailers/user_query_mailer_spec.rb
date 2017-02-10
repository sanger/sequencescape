# frozen_string_literal: true
require 'rails_helper'
require 'timecop'

describe UserQueryMailer, type: :mailer do
  before(:each) do
    new_time = Time.local(2008, 9, 1, 12, 0, 0)
    Timecop.freeze(new_time)
  end

  describe 'request for help' do
    let!(:user_query) { build :user_query }
    let(:mail) { UserQueryMailer.request_for_help(user_query) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Request for help')
      expect(mail.to).to eq(['admin@test.com'])
      expect(mail.from).to eq(['user_abc@example.com'])
    end

    it 'renders the body' do
      body = "<p>This request was sent on September 1st, 2008 12:00, from www.example.com/some_page.</p>\r\n  <p>User was logged in as user_abc.</p>\r\n  <p>What user was trying to do: create.</p>\r\n  <p>What has happened: it did not work.</p>\r\n  <p>What user expected to happen: it to work.</p>"
      expect(mail.body.encoded).to match(body)
    end
  end

  after do
    Timecop.return
  end
end
