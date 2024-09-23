# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReceptaclesController do
  let(:current_user) { create :user }

  let!(:tube) { create(:sample_tube).receptacle }
  let!(:lane) { create :lane }
  let!(:well) { create :untagged_well, study: }
  let(:study) { create :study }

  it_behaves_like 'it requires login'

  describe '#index' do
    before { get :index, params:, session: { user: current_user.id } }

    context 'when no parameters are specified' do
      let(:params) { {} }

      it 'finds all receptacles' do
        expect(assigns(:assets)).to include(well)
        expect(assigns(:assets)).to include(lane)
        expect(assigns(:assets)).to include(tube)
      end
    end

    context 'when a study is specified' do
      let(:params) { { study_id: study.id } }

      it 'finds receptacles associated with a given study' do
        expect(assigns(:assets)).to include(well)
        expect(assigns(:assets)).not_to include(lane)
        expect(assigns(:assets)).not_to include(tube)
      end

      it 'sets the study' do
        expect(assigns(:study)).to eq(study)
      end
    end
  end
end
