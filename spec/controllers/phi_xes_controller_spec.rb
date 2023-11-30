# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhiXesController, :phi_x do
  describe 'GET show' do
    let(:current_user) { create :user }

    before { get :show, session: { user: current_user.id } }

    it 'renders the form' do
      expect(response).to render_template :show
    end

    it 'sets @stock' do
      expect(assigns(:stock)).to be_a PhiX::Stock
    end

    it 'sets @spiked_buffer' do
      expect(assigns(:spiked_buffer)).to be_a PhiX::SpikedBuffer
    end

    it 'sets @tag_option_names' do
      expect(assigns(:tag_option_names)).to eq(%w[Single Dual])
    end
  end
end
