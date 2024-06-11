# frozen_string_literal: true

require 'rails_helper'

describe Admin::PrimerPanelsController do
  let(:primer_panel) { create(:primer_panel) }

  context 'as admin' do
    before { session[:user] = create :admin }

    describe '#index' do
      before { get :index }

      it 'renders the index template' do
        expect(response).to render_template('index')
      end

      it 'finds the primer panels' do
        expect(assigns(:primer_panels)).to eq(PrimerPanel.all)
      end
    end

    describe '#new' do
      before { get :new }

      it 'renders the new template' do
        expect(response).to render_template('new')
      end

      it 'initializes the primer panels' do
        expect(assigns(:primer_panel)).to be_a(PrimerPanel)
      end
    end

    describe '#edit' do
      before { get :edit, params: { id: primer_panel.id } }

      it 'renders the edit template' do
        expect(response).to render_template('edit')
      end

      it 'finds the primer panel' do
        expect(assigns(:primer_panel)).to eq(primer_panel)
      end
    end

    describe '#create' do
      before { post :create, params: { primer_panel: attributes_for(:primer_panel) } }

      it 'renders the edit template' do
        expect(response).to redirect_to admin_primer_panels_path
      end
    end
  end

  context 'as non-admin' do
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

    describe '#edit' do
      it 'redirects' do
        get :edit, params: { id: primer_panel.id }
        expect(response).to redirect_to('/')
      end
    end

    describe '#create' do
      it 'redirects' do
        post :create, params: attributes_for(:primer_panel)
        expect(response).to redirect_to('/')
      end
    end
  end
end
