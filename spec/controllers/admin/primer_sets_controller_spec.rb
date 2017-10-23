# frozen_string_literal: true
# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2017 Genome Research Ltd.

require 'rails_helper'

describe Admin::PrimerSetsController do
  let(:primer_set) { create :primer_set }

  context 'as admin' do

    before do
      session[:user] = create :admin
    end

    describe '#index' do
      before { get :index }

      it "renders the index template" do
        expect(response).to render_template("index")
      end

      it "finds the primer sets" do
        expect(assigns(:primer_sets)).to eq(PrimerSet.all)
      end
    end

    describe '#new' do
      before { get :new }

      it "renders the new template" do
        expect(response).to render_template("new")
      end

      it "initializes the primer sets" do
        expect(assigns(:primer_set)).to be_a(PrimerSet)
      end
    end

    describe '#edit' do
      before { get :edit, params: { id: primer_set.id } }

      it "renders the edit template" do
        expect(response).to render_template("edit")
      end

      it "finds the primer set" do
        expect(assigns(:primer_set)).to eq(primer_set)
      end
    end

    describe '#create' do
      before { post :create, params: { primer_set: attributes_for(:primer_set)} }

      it "renders the edit template" do
        expect(response).to redirect_to admin_primer_sets_path
      end
    end
  end

  context 'as non-admin' do

    before do
      session[:user] = create :user
    end

    describe '#index' do
      it "redirects" do
        get :index
        expect(response).to redirect_to('/login')
      end
    end
    describe '#new' do
      it "redirects" do
        get :new
        expect(response).to redirect_to('/login')
      end
    end
    describe '#edit' do
      it "redirects" do
        get :edit, params: { id: primer_set.id }
        expect(response).to redirect_to('/login')
      end
    end
    describe '#create' do
      it "redirects" do
        post :create, params: attributes_for(:primer_set)
        expect(response).to redirect_to('/login')
      end
    end
  end
end
