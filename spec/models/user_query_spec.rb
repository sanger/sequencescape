require 'rails_helper'
require 'timecop'

describe UserQuery do
  let!(:user) { create :user, login: 'login', email: 'login@example.com' }
  let!(:user_query_attributes) {
    { user_email: 'another_email@example.com',
      user: user,
      url: 'url',
      what_was_trying_to_do: 'create',
      what_happened: 'it did not work',
      what_expected: 'it to work' }
  }
  let(:user_query) { UserQuery.new(user_query_attributes) }
  let(:user_query_with_no_email_provided) { UserQuery.new(user_query_attributes.except(:user_email)) }

  it 'should have a user and a user email' do
    invalid_user_query = UserQuery.new
    expect(invalid_user_query.valid?).to be false
    expect(invalid_user_query.errors.messages.length).to eq 2
    expect(user_query.valid?).to be true
    expect(user_query.user_email).to eq 'another_email@example.com'
    expect(user_query_with_no_email_provided.valid?).to be true
    expect(user_query_with_no_email_provided.user_email).to eq 'login@example.com'
  end

  it 'should know the details of the query, i.e. from, to, date' do
    new_time = Time.local(2017, 2, 6, 12, 0, 0)
    Timecop.freeze(new_time)
    expect(user_query.from).to eq 'another_email@example.com'
    expect(user_query.to).to eq 'admin@test.com'
    expect(user_query.date).to eq 'February 6th, 2017 12:00'
    expect(user_query_with_no_email_provided.from).to eq 'login@example.com'
    expect(user_query_with_no_email_provided.to).to eq 'admin@test.com'
    expect(user_query_with_no_email_provided.date).to eq 'February 6th, 2017 12:00'
    Timecop.return
  end
end
