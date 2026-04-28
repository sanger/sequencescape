# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Studies::InformationController do
  let(:study) { create(:study) }
  let(:user) { create(:user) }

  before { session[:user] = user.id }

  it_behaves_like 'it requires login', 'show', parent: :study

  describe '#show' do
    before { get :show, params: { id: 'unused', study_id: study.id } }

    it 'renders a successful show template', :aggregate_failures do
      expect(subject).to respond_with :success
      expect(subject).to render_template :show
    end
  end

  describe '#show_items' do
    let(:request_type1) { create(:request_type) }
    let(:request_type2) { create(:request_type) }
    let(:well) { create(:untagged_well, study:) }

    before do
      create_list(:request, 3, request_type: request_type1, initial_study: study, asset: well)
      create_list(:request, 2, request_type: request_type2, initial_study: study, asset: well)
      get :show_items, params: { id: 'unused', study_id: study.id }
    end

    it 'responsds with success' do
      expect(subject).to respond_with :success
    end

    it 'renders the items partial' do
      expect(subject).to render_template 'studies/information/_items'
    end

    it 'assigns the summaries variable to the basic tabs and request types' do
      expect(assigns(:summaries)).to eq [
        *Studies::InformationController::BASIC_TABS,
        *[request_type1, request_type2].pluck(:key, :name)
      ]
    end

    describe 'the summary variable' do
      it 'defaults to sample-progress' do
        expect(assigns(:summary)).to eq 'sample-progress'
      end

      it 'can be set by the params' do
        get :show_items, params: { id: 'unused', study_id: study.id, summary: 'assets-progress' }
        expect(assigns(:summary)).to eq 'assets-progress'
      end
    end
  end

  describe '#show_study_summary' do
    before { get :show_study_summary, params: { id: 'unused', study_id: study.id } }

    it 'renders the study summary partial' do
      expect(subject).to render_template 'studies/information/_study_summary'
    end

    it 'assigns the request types variable' do
      expect(assigns(:request_types)).to eq study.request_types
    end
  end

  describe '#study_request_types' do
    let(:request_type1) { create(:request_type, name: 'Request Type 1') }
    let(:request_type2) { create(:request_type, name: 'Request Type 2') }
    let(:well) { create(:untagged_well, study:) }

    before do
      create_list(:request, 3, request_type: request_type1, initial_study: study, asset: well)
      create_list(:request, 2, request_type: request_type2, initial_study: study, asset: well)
      subject.instance_variable_set(:@study, study)
    end

    it 'returns the request types associated with the study ordered by name' do
      expect(subject.send(:study_request_types)).to eq [request_type1, request_type2]
    end

    it 'only returns standard request types' do
      # Non standard request
      request_type3 = create(:request_type, name: 'Request Type 3', request_purpose: :internal)
      create_list(:request, 2, request_type: request_type3, initial_study: study, asset: well)

      expect(subject.send(:study_request_types)).to eq [request_type1, request_type2]
    end
  end
end
