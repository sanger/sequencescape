require 'rails_helper'

RSpec.describe TubeRackSummariesController, type: :controller do
  let(:current_user) { create :user }

  describe '#show' do
    let(:tube_rack) { create :tube_rack }
    setup { get :show, params: {id: tube_rack.primary_barcode.barcode}, session: { user: current_user.id } }
    it 'gets the tube rack by barcode' do
      expect(assigns(:tube_rack)).to include(tube_rack)
    end
  end
end
