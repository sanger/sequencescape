require 'rails_helper'

RSpec.describe Accession::Contact, type: :model, accession: true do
  before(:all) do
    @email = configatron.default_email_domain
    configatron.default_email_domain = 'example.com'
  end

  let!(:user) { create(:user, login: 'user1', first_name: 'Santa', last_name: 'Claus') }
  subject { Accession::Contact.new(user) }

  it 'should have a name' do
    expect(subject.name).to eq('Santa Claus')
  end

  it 'should have an email' do
    expect(subject.email).to eq('user1@example.com')
  end

  it 'should produce a hash for the xml' do
    hsh = subject.to_h
    expect(hsh[:inform_on_error]).to eq(subject.email)
    expect(hsh[:inform_on_status]).to eq(subject.email)
    expect(hsh[:name]).to eq(subject.name)
  end

  after(:all) do
    configatron.default_email_domain = @email
  end
end
