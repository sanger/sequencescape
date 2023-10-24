# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhiX::SpikedBuffersController, :phi_x do
  describe 'POST create' do
    let(:current_user) { create :user }
    let(:library_tube) { create :phi_x_stock_tube, name: 'PhiX Stock' }

    before { post :create, params: { phi_x_spiked_buffer: form_parameters }, session: { user: current_user.id } }

    context 'with valid parameters' do
      let(:form_parameters) do
        { name: 'My name', parent_barcode: library_tube.human_barcode, concentration: '0.3', volume: '10', number: '2' }
      end

      it 'records the created tubes' do
        expect(assigns(:spiked_buffers)).to have(2).items
      end

      it 'renders the show page' do
        expect(response).to render_template :show
      end
    end

    context 'with invalid parameters' do
      let(:form_parameters) { { name: '', parent_barcode: 'Fake', concentration: '-0.3', number: 'two' } }

      it 'renders the new page' do
        expect(response).to render_template :new
      end

      it 'sets @stock' do
        expect(assigns(:spiked_buffer)).to be_a PhiX::SpikedBuffer
      end
    end
  end
end
