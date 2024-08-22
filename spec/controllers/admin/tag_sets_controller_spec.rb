# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::TagSetsController do
  let(:current_user) { create :user }
  let(:tag_set) { create :tag_set }

  it_behaves_like 'it requires login'

  context 'when admin' do
    before { session[:user] = create :admin }

    describe '#index' do
      before { get :index }

      it 'is successful' do
        expect(response).to have_http_status(:success)
        expect(response).to render_template('index')
      end
    end

    describe '#show' do
      let(:tag_set) { create :tag_set }

      before { get :show, params: { id: tag_set.id } }

      it 'is successful' do
        expect(response).to have_http_status(:success)
        expect(response).to render_template('show')
      end
    end

    describe '#new' do
      before { get :new }

      it 'is successful' do
        expect(response).to have_http_status(:success)
        expect(response).to render_template('new')
      end
    end

    describe '#create' do
      it 'redirects to the tag set show path' do
        post :create, params: { tag_set: { name: 'test-123', tag_group_id: create(:tag_group).id } }
        expect(response).to redirect_to admin_tag_set_path(TagSet.last)
      end

      it 'renders the new template when there are errors' do
        post :create, params: { tag_set: { name: 'test-123', tag_group_id: 'bad ID' } }
        # Successful status because we handle and display the errors and remain on the new page
        expect(response).to have_http_status(:success)
        expect(response).to render_template('new')
      end
    end
  end

  context 'when a non-admin' do
    before { session[:user] = create :user }

    describe '#index' do
      it 'redirects' do
        get :index
        expect(response).to redirect_to('/')
      end
    end

    describe '#new' do
      it 'redirects' do
        get :new
        expect(response).to redirect_to('/')
      end
    end

    describe '#show' do
      it 'redirects' do
        tag_set = create(:tag_set)
        get :show, params: { id: tag_set.id }
        expect(response).to redirect_to('/')
      end
    end

    describe '#create' do
      it 'redirects' do
        post :create, params: attributes_for(:tag_set)
        expect(response).to redirect_to('/')
      end
    end
  end
end
