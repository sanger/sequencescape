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
end
