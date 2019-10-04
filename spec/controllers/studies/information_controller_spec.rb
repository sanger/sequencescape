# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Studies::InformationController do
  let(:study) { create :study }
  let(:user) { create(:user) }

  it_behaves_like 'it requires login', 'show', parent: :study

  setup do
    session[:user] = user.id
  end

  describe '#show' do
    setup do
      get :show, params: { id: 'unused', study_id: study.id }
    end

    it 'renders a successful show template', :aggregate_failures do
      expect(subject).to respond_with :success
      expect(subject).to render_template :show
    end
  end

  describe '#show with requests' do
    let(:request_type1) { create :request_type }
    let(:request_type2) { create :request_type }
    let(:request_type3) { create :request_type }
    let(:well) { create :untagged_well, study: study }

    setup do
      request_type3
      create_list(:request, 2, request_type: request_type1, initial_study: study, asset: well)
      create_list(:request, 3, request_type: request_type2, initial_study: study, asset: well)
      get :show, params: { id: 'unused', study_id: study.id }
    end

    # Note: This currently has some limitations when it comes to assigning requests to studies
    # This test has been added purely to cover existing behaviour, while the statistics are
    # refactored. It does not fix the study-requests scope
    it 'detects used request types' do
      expect(assigns(:request_types)).to eq([request_type1, request_type2])
    end
  end
end
