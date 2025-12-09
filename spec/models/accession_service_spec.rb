# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AccessionService do
  describe '.select_for_study' do
    context 'when given an open study' do
      let(:study) { create(:open_study) }

      it 'returns ENAService' do
        expect(described_class.select_for_study(study)).to be_a(AccessionService::ENAService)
      end
    end

    context 'when given a managed study' do
      let(:study) { create(:managed_study) }

      it 'returns EGAService' do
        expect(described_class.select_for_study(study)).to be_a(AccessionService::EGAService)
      end
    end

    context 'when given a study with other data release strategy' do
      let(:study) { create(:not_app_study) }

      it 'returns NoService' do
        expect(described_class.select_for_study(study)).to be_a(AccessionService::NoService)
      end
    end
  end

  describe '.send_samples_to_service?' do
    context 'when no study accession needed' do
      let(:study) { create(:not_app_study) }

      it 'returns true' do
        expect(described_class.send_samples_to_service?(study)).to be(true)
      end
    end

    context 'when study accession is required' do
      let(:study) { create(:open_study, study_metadata:, accession_number:) }

      context 'when never release is false' do
        let(:study_metadata) { create(:study_metadata, data_release_timing: Study::DATA_RELEASE_TIMING_STANDARD) }

        context 'when study accession number is present' do
          let(:accession_number) { 'ENA123' }

          it 'returns true' do
            expect(described_class.send_samples_to_service?(study)).to be(true)
          end
        end

        context 'when study accession number is absent' do
          let(:accession_number) { nil }

          it 'returns false' do
            expect(described_class.send_samples_to_service?(study)).to be(false)
          end
        end
      end

      context 'when never release is true' do
        let(:study_metadata) do
          create(:study_metadata,
                 data_release_timing: Study::DATA_RELEASE_TIMING_NEVER,
                 data_release_prevention_reason:
                    'Prevent harm (e.g sensitive studies or biosecurity) - DAC approval required')
        end

        context 'when study accession number is present' do
          let(:accession_number) { 'ENA123' }

          it 'returns false' do
            expect(described_class.send_samples_to_service?(study)).to be(false)
          end
        end

        context 'when study accession number is absent' do
          let(:accession_number) { nil }

          it 'returns false' do
            expect(described_class.send_samples_to_service?(study)).to be(false)
          end
        end
      end
    end
  end

  describe '.select_for_sample' do
    let(:sample) { create(:sample, studies:) }

    context 'when sample has one open study' do
      let(:open_study) { create(:open_study, accession_number: 'ENA123') }
      let(:studies) { [open_study] }

      it 'returns an instance of the ENA service' do
        expect(described_class.select_for_sample(sample)).to be_a(AccessionService::ENAService)
      end
    end

    context 'when sample has one managed study' do
      let(:managed_study) { create(:managed_study, accession_number: 'EGA123') }
      let(:studies) { [managed_study] }

      it 'returns an instance of the EGA service' do
        expect(described_class.select_for_sample(sample)).to be_a(AccessionService::EGAService)
      end
    end

    context 'when sample has one un-accessioned study' do
      let(:open_study) { create(:open_study) }
      let(:studies) { [open_study] }

      it 'returns UnsuitableService' do
        expect(described_class.select_for_sample(sample)).to be_a(AccessionService::UnsuitableService)
      end
    end

    context 'when sample has one study that does not require accessioning' do
      let(:other_study) { create(:not_app_study) }
      let(:studies) { [other_study] }

      it 'returns NoService' do
        expect(described_class.select_for_sample(sample)).to be_a(AccessionService::NoService)
      end
    end

    context 'when sample has multiple eligible studies' do
      let(:open_study) { create(:open_study, accession_number: 'ENA123') }
      let(:managed_study) { create(:managed_study, accession_number: 'EGA123') }
      let(:other_study) { create(:not_app_study) }
      let(:studies) { [open_study, managed_study, other_study] }

      it 'returns an instance of the highest priority accession service' do
        expect(described_class.select_for_sample(sample)).to be_a(AccessionService::EGAService)
      end
    end

    context 'when sample has no eligible studies' do
      let(:sample) { create(:sample, studies: []) }

      it 'returns UnsuitableService' do
        expect(described_class.select_for_sample(sample)).to be_a(AccessionService::UnsuitableService)
      end
    end

    # We prioritise the EGA, as its the more conservative of the two databases
    # and it reduces the risk of accidentally making human data public
    context 'when sample has an open study and a managed study' do
      let(:open_study) { create(:open_study, accession_number: 'ENA123') }
      let(:managed_study) { create(:managed_study, accession_number: 'EGA123') }
      let(:studies) { [open_study, managed_study] }

      it 'returns an instance of the EGA service' do
        expect(described_class.select_for_sample(sample)).to be_a(AccessionService::EGAService)
      end
    end

    context 'when sample has a managed study and an open study (in the other order)' do
      let(:managed_study) { create(:managed_study, accession_number: 'EGA123') }
      let(:open_study) { create(:open_study, accession_number: 'ENA123') }
      let(:studies) { [managed_study, open_study] }

      it 'returns an instance of the EGA service' do
        expect(described_class.select_for_sample(sample)).to be_a(AccessionService::EGAService)
      end
    end

    # We err on the side of caution here - inadvertently sending data to the ENA could be an issue.
    context 'when sample has an accessioned open study but un-accessioned managed study' do
      let(:open_study) { create(:open_study, accession_number: 'ENA123') }
      let(:managed_study) { create(:managed_study) }
      let(:studies) { [open_study, managed_study] }

      it 'returns UnsuitableService' do
        expect(described_class.select_for_sample(sample)).to be_a(AccessionService::UnsuitableService)
      end
    end
  end
end
