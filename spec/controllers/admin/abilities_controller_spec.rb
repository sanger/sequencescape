# frozen_string_literal: true

require 'rails_helper'

describe Admin::AbilitiesController do
  context 'when admin' do
    before { session[:user] = create :admin }

    describe '#index' do
      before { get :index }

      it 'renders the index template' do
        expect(response).to render_template('index')
      end

      it 'set the permission info' do
        expect(assigns(:roles)).to be_an Array
        expect(assigns(:permissions)).to be_an Array
      end
    end
  end
end
