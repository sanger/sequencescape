# frozen_string_literal: true

require 'rails_helper'

# Related authentication tests are in test/controllers/authentication_controller_test.rb

RSpec.describe SessionsController, type: :controller do
  describe 'POST #login' do
    let(:user) { instance_double(User, id: 1) }

    context 'when login is successful' do
      before do
        allow(User).to receive(:authenticate).with('valid_user', 'valid_password').and_return(user)
        allow(controller).to receive(:logged_in?).and_return(true)

        post :login, params: { login: 'valid_user', password: 'valid_password' }
      end

      it 'displays a success flash message' do
        expect(flash[:notice]).to eq('Logged in successfully')
      end

      it 'redirects to the default controller' do
        expect(response).to redirect_to(controller: :studies)
      end
    end

    context 'when login fails' do
      before do
        allow(User).to receive(:authenticate).with('invalid_user', 'invalid_password').and_return(nil)
        allow(controller).to receive(:logged_in?).and_return(false)

        post :login, params: { login: 'invalid_user', password: 'invalid_password' }
      end

      it 'returns the login page' do
        expect(response).to render_template(:login)
      end

      it 'displays an appropriate flash message' do
        expect(flash.now[:error]).to eq('Please try again using your Sanger login details.')
      end
    end
  end

  describe 'GET #logout' do
    before do
      allow(controller).to receive_messages(logged_in?: true, current_user: instance_double(User, forget_me: true))

      get :logout
    end

    it 'displays an appropriate flash message' do
      expect(flash[:notice]).to eq('You have been logged out.')
    end

    it 'redirects to the default controller' do
      expect(response).to redirect_to(controller: :studies)
    end
  end
end
