# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SamplesController, type: :controller do
  let(:sample) { create :sample }
  let(:current_user) { create :user }

  it_behaves_like 'it requires login'

  describe '#update' do
    context 'when the user is the owner of the study' do
      before do
        current_user.roles.create(authorizable_id: sample.id, authorizable_type: 'Sample', name: 'owner')
      end

      context 'when changing withdraw consent' do
        let(:consent) { true }
        let(:action) do
          post :update, session: { user: current_user.id }, params: {
            id: sample.id, sample: { sample_metadata_attributes: { consent_withdrawn: consent } }
          }
          sample.reload
        end

        it 'changes the consent withdrawn' do
          expect { action }.to change(sample, :consent_withdrawn).to(true)
        end

        it 'sets a timestamp in the sample' do
          expect { action }.to change(sample, :date_of_consent_withdrawn).from(nil)
        end

        it 'sets the user that changed the consent' do
          expect { action }.to change(sample, :user_id_of_consent_withdrawn).from(nil).to(current_user.id)
        end
      end
    end
  end
end
