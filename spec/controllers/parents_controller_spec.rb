# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParentsController do
  let(:current_user) { create(:user) }

  it_behaves_like 'it requires login', 'show', parent: :receptacle

  describe '#show' do
    let(:child) { create(:lane) }
    let(:parents) { create_list(:library_tube, parent_number).map(&:receptacle) }

    before do
      parents.each { |parent| create(:sequencing_request, target_asset: child, asset: parent) }
      child.reload
      get :show, params: { receptacle_id: child.id }, session: { user: current_user.id }
    end

    context 'with a parentless receptacle' do
      let(:parent_number) { 0 }

      it 'returns a 404' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with a single parent receptacle' do
      let(:parent_number) { 1 }

      it 'redirects to the parent' do
        expect(response).to redirect_to(receptacle_path(parents.first))
      end
    end

    context 'with a multiple parent receptacle' do
      let(:parent_number) { 2 }

      it 'renders multiple options' do
        expect(response).to have_http_status(:multiple_choices)
      end

      it 'renders a disambiguation page' do
        expect(assigns(:parents)).to eq(parents)
      end
    end
  end
end
