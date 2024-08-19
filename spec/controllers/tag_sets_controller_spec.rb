# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagSetsController do
  let(:current_user) { create :user }

  it_behaves_like 'it requires login'

  describe '#index' do
    before { get :index, session: { user: current_user.id } }

    it 'is successful' do
      expect(response).to have_http_status(:success)
      expect(response).to render_template('index')
    end
  end

  describe '#show' do
    let(:tag_set) { create :tag_set }

    before { get :show, params: { id: tag_set.id }, session: { user: current_user.id } }

    it 'is successful' do
      expect(response).to have_http_status(:success)
      expect(response).to render_template('show')
    end
  end
end
