# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessengersController do
  let(:user) { create :user }
  let(:messenger) { create :messenger }

  it_behaves_like 'it requires login', 'show', resource: :messenger

  setup do
    session[:user] = user.id
  end

  describe '#show' do
    setup { get :show, params: { id: messenger.id } }

    it { is_expected.to respond_with :success }

    it 'returns the messenger payload' do # rubocop:todo RSpec/AggregateExamples
      expect(response.body).to eq(messenger.to_json)
    end
  end
end
