# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessengersController do
  let(:user) { create(:user) }
  let(:messenger) { create(:messenger) }

  before { session[:user] = user.id }

  it_behaves_like 'it requires login', 'show', resource: :messenger

  describe '#show' do
    before { get :show, params: { id: messenger.id } }

    it { is_expected.to respond_with :success }

    it 'returns the messenger payload' do
      expect(response.body).to eq(messenger.to_json)
    end
  end
end
