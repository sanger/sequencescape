# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::Contact, :accession, type: :model do
  subject { described_class.new(user) }

  before(:all) do
    @email = configatron.default_email_domain
    configatron.default_email_domain = 'example.com'
  end

  let!(:user) { create(:user, login: 'user1', first_name: 'Santa', last_name: 'Claus') }

  after(:all) { configatron.default_email_domain = @email }

  it 'has a name' do
    expect(subject.name).to eq('Santa Claus')
  end

  it 'has an email' do
    expect(subject.email).to eq('user1@example.com')
  end

  it 'produces a hash for the xml' do
    hsh = subject.to_h
    expect(hsh[:inform_on_error]).to eq(subject.email)
    expect(hsh[:inform_on_status]).to eq(subject.email)
    expect(hsh[:name]).to eq(subject.name)
  end
end
