# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhiX::StocksController, :phi_x do
  describe 'POST create' do
    let(:current_user) { create :user }
    let(:study) { create :study }

    before { post :create, params: { phi_x_stock: form_parameters }, session: { user: current_user.id } }

    context 'with valid parameters' do
      let(:form_parameters) do
        { name: 'My name', tags: 'Single', concentration: '0.3', number: '2', study_id: study.id }
      end

      it 'records the created tubes' do
        expect(assigns(:stocks)).to have(2).items
      end

      it 'renders the create page' do
        expect(response).to render_template :show
      end
    end

    context 'with invalid parameters' do
      let(:form_parameters) { { name: 'My name', tags: 'Single', concentration: '-0.3', number: 'two' } }

      it 'renders the create page' do
        expect(response).to render_template :new
      end

      it 'sets @stock' do
        expect(assigns(:stock)).to be_a PhiX::Stock
      end
    end
  end
end
