# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SamplesController do
  let(:sample) { create(:sample) }
  let(:current_user) { create(:user) }

  it_behaves_like 'it requires login'

  describe '#update' do
    context 'when the user is the owner of the study' do
      before { current_user.roles.create(authorizable_id: sample.id, authorizable_type: 'Sample', name: 'owner') }

      let(:action) do
        post :update,
             session: {
               user: current_user.id
             },
             params: {
               id: sample.id,
               sample: {
                 sample_metadata_attributes: {
                   consent_withdrawn: consent
                 }
               }
             }
        sample.reload
      end

      context 'when consent withdrawn starts off false' do
        context 'when changing withdraw consent' do
          let(:consent) { true }

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

        context 'when not changing withdraw consent' do
          let(:consent) { false }

          it 'does not change the consent withdrawn' do
            expect { action }.not_to change(sample, :consent_withdrawn)
          end

          it 'does not set a timestamp in the sample' do
            expect { action }.not_to change(sample, :date_of_consent_withdrawn)
          end

          it 'does not set the user that changed the consent' do
            expect { action }.not_to change(sample, :user_id_of_consent_withdrawn)
          end
        end
      end

      context 'when consent withdrawn starts off true' do
        let(:sample) do
          create(
            :sample,
            consent_withdrawn: true,
            date_of_consent_withdrawn: Time.zone.today,
            user_id_of_consent_withdrawn: current_user.id
          )
        end

        context 'when changing withdraw consent' do
          let(:consent) { false }

          it 'changes the consent withdrawn' do
            expect { action }.to change(sample, :consent_withdrawn).to(false)
          end

          it 'does not change the timestamp' do
            expect { action }.not_to change(sample, :date_of_consent_withdrawn)
          end

          it 'does not change the user that changed the consent' do
            expect { action }.not_to change(sample, :user_id_of_consent_withdrawn)
          end
        end

        context 'when not changing withdraw consent' do
          let(:consent) { true }

          it 'does not change the consent withdrawn' do
            expect { action }.not_to change(sample, :consent_withdrawn)
          end

          it 'does not set a timestamp in the sample' do
            expect { action }.not_to change(sample, :date_of_consent_withdrawn)
          end

          it 'does not set the user that changed the consent' do
            expect { action }.not_to change(sample, :user_id_of_consent_withdrawn)
          end
        end
      end
    end
  end

  describe '#accession' do
    context 'when accessioning is disabled' do
      before do
        get :accession,
            params: { id: sample.id },
            session: { user: current_user.id }
      end

      it 'redirects to the sample page' do
        expect(response).to redirect_to(sample_path(sample.id))
      end

      it 'displays an error message indicating accessioning is not enabled' do
        expect(flash[:error]).to eq('Accessioning Service Failed: Accessioning is not enabled in this environment.')
      end
    end
  end
end
