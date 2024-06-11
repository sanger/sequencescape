# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequenomQcPlatesController, :phi_x do
  describe 'GET index' do
    let(:current_user) { create(:user) }

    before do
      create_list(:sequenom_qc_plate, 2)
      get :index, session: { user: current_user.id }
    end

    it 'renders the form' do
      expect(response).to render_template :index
    end

    it 'sets @sequenom_qc_plates' do
      expect(assigns(:sequenom_qc_plates)).to have(2).items
    end
  end
end
