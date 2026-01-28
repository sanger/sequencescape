# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SamplesController do
  include AccessionV1ClientHelper
  include MockAccession

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
    let(:accession_individual_samples_with_sample_accessioning_job) { false }

    before do
      if accession_individual_samples_with_sample_accessioning_job
        Flipper.enable :y25_286_accession_individual_samples_with_sample_accessioning_job

        create(:user, api_key: configatron.accession_local_key) # create contact user
        allow(Accession::Submission).to receive(:client).and_return(
          stub_accession_client(:submit_and_fetch_accession_number, return_value: 'EGA00001000240')
        )
      else
        Flipper.disable :y25_286_accession_individual_samples_with_sample_accessioning_job

        allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(successful_sample_accession_response)
      end

      get :accession,
          params: { id: sample.id },
          session: { user: current_user.id }
    end

    context 'when accessioning is disabled', :accessioning_disabled do
      it 'redirects to the sample page' do
        expect(response).to redirect_to(sample_path(sample.id))
      end

      it 'displays an error message indicating accessioning is not enabled' do
        expect(flash[:error]).to eq('Accessioning Service Failed: Accessioning is not enabled in this environment.')
      end
    end

    context 'when accessioning is enabled', :accessioning_enabled do
      context 'when required fields are missing for accessioning' do
        let(:studies) { [create(:managed_study, accession_number: 'ENA123')] }
        let(:sample_metadata) { create(:minimal_sample_metadata_for_accessioning) } # sample missing required metadata
        let(:sample) { create(:sample, sample_metadata:, studies:) }

        it 'asserts that the associated study is valid for accessioning' do
          expect(sample.ena_study).to be_valid(:accession)
        end

        it 'asserts that the phenotype is missing' do
          expect(sample.sample_metadata.phenotype).to be_nil
        end

        it 'asserts that the gender is missing' do
          expect(sample.sample_metadata.gender).to be_nil
        end

        it 'asserts that the sample is valid on accession' do
          expect(sample).to be_valid(:accession)
        end

        it 'asserts that the sample is valid on ENA accession' do
          expect(sample).to be_valid(:ENA)
        end

        it 'asserts that the sample is NOT valid on EGA accession' do
          expect(sample).not_to be_valid(:EGA)
        end

        it 'redirects to the sample edit page' do
          expect(response).to redirect_to(edit_sample_path(sample.id))
        end

        it 'does not display a notice message' do
          expect(flash[:notice]).to be_nil
        end

        it 'does not display a warning message' do
          expect(flash[:warning]).to be_nil
        end

        it 'displays an error message indicating the validation failure' do
          expect(flash[:error]).to eq(<<~MSG.squish)
            Please fill in the required fields:
            Sample metadata gender is required, Sample metadata phenotype is required,
            Sample metadata donor is required, Sample metadata is invalid
          MSG
        end
      end

      context 'when accessioning is successful' do
        let(:studies) { [create(:managed_study, accession_number: 'ENA123')] }
        let(:sample_metadata) { create(:sample_metadata_for_accessioning) }
        let(:sample) { create(:sample, sample_metadata:, studies:) }

        before { sample.reload } # Reload to get updated accession number

        context 'when the accession_individual_samples_with_sample_accessioning_job feature flag is disabled' do
          let(:accession_individual_samples_with_sample_accessioning_job) { false }

          it 'assigns an accession number to the sample' do
            expect(sample.ebi_accession_number).to eq('EGA00001000240')
          end

          it 'redirects to the sample page' do
            expect(response).to redirect_to(sample_path(sample.id))
          end

          it 'displays a notice message with the generated accession number' do
            expect(flash[:notice]).to eq("Accession number generated: #{sample.ebi_accession_number}")
          end
        end

        context 'when the accession_individual_samples_with_sample_accessioning_job feature flag is enabled' do
          let(:accession_individual_samples_with_sample_accessioning_job) { true }

          it 'assigns an accession number to the sample' do
            expect(sample.ebi_accession_number).to eq('EGA00001000240')
          end

          it 'redirects to the sample page' do
            expect(response).to redirect_to(sample_path(sample.id))
          end

          it 'displays a notice message with the generated accession number' do
            expect(flash[:notice]).to eq("Accession number generated: #{sample.ebi_accession_number}")
          end

          context 'when a network error occurs during accessioning' do
            before do
              allow(Accession::Submission).to receive(:client).and_return(
                stub_accession_client(:submit_and_fetch_accession_number,
                                      raise_error: Faraday::ConnectionFailed.new('Network connection failed'))
              )

              get :accession,
                  params: { id: sample.id },
                  session: { user: current_user.id }
            end

            it 'redirects to the sample page' do
              expect(response).to redirect_to(sample_path(sample.id))
            end

            it 'displays an error message indicating a network error occurred' do
              expect(flash[:error]).to eq('Accessioning failed with a network error: Network connection failed')
            end
          end
        end

        context 'when updating an existing accessioned sample' do
          before do
            #  re-accession the sample to update the accessioned metadata
            get :accession,
                params: { id: sample.id },
                session: { user: current_user.id }
          end

          it 'does not change the accession number' do
            expect(sample.ebi_accession_number).to eq('EGA00001000240')
          end

          it 'redirects to the sample page' do
            expect(response).to redirect_to(sample_path(sample.id))
          end

          it 'displays a notice message indicating the metadata was updated' do
            expect(flash[:notice]).to eq('Accessioned metadata updated')
          end
        end
      end
    end
  end
end
