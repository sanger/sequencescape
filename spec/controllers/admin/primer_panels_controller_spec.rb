# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2017 Genome Research Ltd.

require 'rails_helper'

describe Admin::PrimerPanelsController do
  let(:primer_panel) { create :primer_panel }

  context 'as admin' do
    before do
      session[:user] = create :admin
    end

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
    before do
      session[:user] = create :user
    end

    describe '#index' do
      it 'redirects' do
        get :index
        expect(response).to redirect_to('/login')
      end
    end
    describe '#new' do
      it 'redirects' do
        get :new
        expect(response).to redirect_to('/login')
      end
    end
    describe '#edit' do
      it 'redirects' do
        get :edit, params: { id: primer_panel.id }
        expect(response).to redirect_to('/login')
      end
    end
    describe '#create' do
      it 'redirects' do
        post :create, params: attributes_for(:primer_panel)
        expect(response).to redirect_to('/login')
      end
    end
  end
end
