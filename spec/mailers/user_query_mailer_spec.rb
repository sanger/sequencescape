# frozen_string_literal: true

require 'rails_helper'
require 'timecop'

describe UserQueryMailer do
  before do
    new_time = Time.zone.local(2008, 9, 1, 12, 0, 0)
    Timecop.freeze(new_time)
  end

  after { Timecop.return }

  describe 'request for help' do
    let!(:user_query) { build :user_query }
    let(:mail) { described_class.request_for_help(user_query) }

    let(:expected_body) { <<~HEREDOC }
        Dear developer,

          <p>This request was sent on September 1st, 2008 12:00, from www.example.com/some_page.</p>
          <p>User was logged in as user_abc.</p>
          <p>What user was trying to do: create.</p>
          <p>What has happened: it did not work.</p>
          <p>What user expected to happen: it to work.</p>

        Thank you
      HEREDOC

    it 'renders the headers' do
      expect(mail.subject).to eq('Request for help')
      expect(mail.to).to eq(['admin@test.com'])
      expect(mail.from).to eq(['user_abc@example.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded.delete("\r")).to match(expected_body)
    end
  end
end
