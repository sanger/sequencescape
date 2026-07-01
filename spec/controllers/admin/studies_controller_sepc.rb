# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::StudiesController do
  let(:current_user) { create(:admin) }
  let(:session) { { user: current_user.id } }
  let(:study) { create(:study) }

  describe '#index' do
    before { get :index, session: session }

    it 'responds with 200' do
      expect(response).to have_http_status(:ok)
    end

    it 'assigns @studies' do
      expect(assigns(:studies)).to eq(Study.alphabetical)
    end
  end

  describe '#show' do
    context 'with a regular study' do
      before { get :show, session: session, params: { id: study.id } }

      it 'responds with 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'assigns @page_name to the study name' do
        expect(assigns(:page_name)).to eq(study.name)
      end
    end

    context 'with a mastered study', :sapio_restrictions_enabled do
      let(:mastered_study) { create(:study, mastered_in_sapio: true) }

      before { get :show, session: session, params: { id: mastered_study.id } }

      it 'redirects to study_information_path with an error flash', :aggregate_failures do
        expect(response).to redirect_to(study_information_path(mastered_study))
        expect(flash[:error]).to eq(I18n.t('studies.managed_in_sapio.warning_message_1'))
      end
    end

    context 'with a mastered study when sapio restrictions are disabled', :sapio_restrictions_disabled do
      let(:mastered_study) { create(:study, mastered_in_sapio: true) }

      before { get :show, session: session, params: { id: mastered_study.id } }

      it 'responds with 200 and does not set an error flash', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(flash[:error]).to be_nil
      end
    end
  end

  describe '#edit' do
    context 'with a valid study id (member GET)' do
      before { get :edit, session: session, params: { id: study.id } }

    #   it 'assigns @request_types' do
    #     expect(assigns(:request_types)).to be_present
    #   end

      it 'renders the edit partial' do
        expect(response).to render_template(partial: '_edit')
      end
    end

    # context 'with id 0 (collection POST)' do
    #   before { post :edit, session: session, params: { id: '0' } }

    #   it 'renders nothing' do
    #     expect(response.body).to be_empty
    #   end
    # end

    context 'with a mastered study (member GET)', :sapio_restrictions_enabled do
      let(:mastered_study) { create(:study, mastered_in_sapio: true) }

      before { get :edit, session: session, params: { id: mastered_study.id } }

      it 'redirects to study_information_path with an error flash', :aggregate_failures do
        expect(response).to redirect_to(study_information_path(mastered_study))
        expect(flash[:error]).to eq(I18n.t('studies.managed_in_sapio.warning_message_1'))
      end
    end
  end

  describe '#update' do
    context 'with a regular study' do
      before { put :update, session: session, params: { id: study.id, study: { name: study.name } } }

      it 'renders the manage_single_study partial' do
        expect(response).to render_template(partial: '_manage_single_study')
      end

      it 'sets a notice flash' do
        expect(subject).to set_flash.now.to('Your study has been updated')
      end
    end

    context 'with a mastered study', :sapio_restrictions_enabled do
      let(:mastered_study) { create(:study, mastered_in_sapio: true) }

      before { put :update, session: session, params: { id: mastered_study.id, study: {} } }

      it 'redirects to study_information_path with an error flash', :aggregate_failures do
        expect(response).to redirect_to(study_information_path(mastered_study))
        expect(flash[:error]).to eq(I18n.t('studies.managed_in_sapio.warning_message_1'))
      end
    end
  end
end