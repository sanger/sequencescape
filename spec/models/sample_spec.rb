# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

RSpec.describe Sample, :accession, :cardinal do
  include AccessionV1ClientHelper

  # TODO: remove accessioning out of samples specs
  context 'accessioning disabled' do
    let!(:user) { create(:user, api_key: configatron.accession_local_key) }
    let(:sample) do
      create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
    end

    before do
      configatron.accession_samples = false
    end

    around do |example|
      Delayed::Worker.delay_jobs = false
      example.run
      Delayed::Worker.delay_jobs = true
    end

    it 'will raise an exception if the sample can be accessioned' do
      expect { sample.accession }.to raise_error(AccessionService::AccessioningDisabledError)
    end

    it 'will not add an accession number if it fails' do
      begin
        sample.accession
      rescue AccessionService::AccessioningDisabledError
        # Ignore the error and continue execution
      end
      expect(sample.sample_metadata.sample_ebi_accession_number).to be_nil
    end
  end

  # TODO: remove accessioning out of samples specs
  context 'accessioning enabled', :accessioning_enabled do
    let!(:user) { create(:user, api_key: configatron.accession_local_key) }

    around do |example|
      Delayed::Worker.delay_jobs = false
      example.run
      Delayed::Worker.delay_jobs = true
    end

    context 'sample fails internal validations and is not suitable for accessioning' do
      let(:unaccessionable_sample) do
        create(:sample_for_accessioning_with_open_study,
               sample_metadata: create(:sample_metadata_for_accessioning, sample_taxon_id: nil))
      end

      it 'will provide debug information' do
        sample_name = unaccessionable_sample.name

        expect { unaccessionable_sample.accession }.to raise_error(AccessionService::AccessionServiceError) do |error|
          expect(error.message).to eq(
            "Sample '#{sample_name}' cannot be accessioned: " \
            'Sample does not have the required metadata: sample-taxon-id.'
          )
        end
      end
    end

    context 'the sample has passed internal validations' do
      let(:accessionable_sample) do
        create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
      end

      it 'will not proceed if accessioning for the study is disabled' do
        accessionable_sample.ena_study.enforce_accessioning = false
        accessionable_sample.accession

        expect(accessionable_sample.sample_metadata.sample_ebi_accession_number).to be_nil
      end

      context 'when accessioning succeeds' do
        before do
          allow(Accession::Submission).to receive(:client).and_return(
            stub_accession_client(:submit_and_fetch_accession_number, return_value: 'EGA00001000240')
          )
          accessionable_sample.accession
        end

        it 'will add an accession number' do
          expect(accessionable_sample.sample_metadata.sample_ebi_accession_number).to be_present
        end
      end

      context 'when accessioning fails' do
        before do
          allow(Accession::Submission).to receive(:client).and_return(
            stub_accession_client(:submit_and_fetch_accession_number,
                                  raise_error: Accession::Error.new('Failed to process accessioning response'))
          )
        end

        it 'will not add an accession number' do
          accessionable_sample.save!

          expect(accessionable_sample.sample_metadata.sample_ebi_accession_number).to be_nil
        end

        it 'will log an error' do
          allow(Rails.logger).to receive(:error).and_call_original

          expect { accessionable_sample.accession }.to raise_error(StandardError)

          expect(Rails.logger).to have_received(:error).with(
            "SampleAccessioningJob failed for sample '#{accessionable_sample.name}': " \
            'Failed to process accessioning response'
          )
        end

        it 'will send an exception notification' do
          allow(ExceptionNotifier).to receive(:notify_exception)

          expect { accessionable_sample.accession }.to raise_error(StandardError)

          sample_name = accessionable_sample.name # 'Sample1'
          expect(ExceptionNotifier).to have_received(:notify_exception)
            .with(instance_of(Accession::Error),
                  data: { message: "SampleAccessioningJob failed for sample '#{sample_name}': " \
                                   'Failed to process accessioning response',
                          sample_name: sample_name,
                          service_provider: 'ENA' })
        end
      end
    end
  end

  context 'can be included in submission' do
    it 'knows if it was registered through manifest' do
      stand_alone_sample = create(:sample)
      expect(stand_alone_sample).not_to be_registered_through_manifest

      sample_manifest = create(:tube_sample_manifest_with_samples)
      sample_manifest.samples.each { |sample| expect(sample).to be_registered_through_manifest }
    end

    it 'knows when it can be included in submission if it was registered through manifest' do
      sample_manifest = create(:tube_sample_manifest_with_samples)
      sample_manifest.samples.each { |sample| expect(sample).not_to be_can_be_included_in_submission }
      sample = sample_manifest.samples.first
      sample.sample_metadata.supplier_name = 'new sample'
      expect(sample).to be_can_be_included_in_submission
    end

    it 'knows when it can be included in submission if it was not registered through manifest' do
      sample = create(:sample)
      expect(sample).to be_can_be_included_in_submission
    end
  end

  context 'consent withdraw' do
    let(:user) { create(:user) }
    let(:time) { DateTime.now }
    let(:sample) { create(:sample) }

    before do
      sample.update(consent_withdrawn: true, date_of_consent_withdrawn: time, user_id_of_consent_withdrawn: user.id)
    end

    it 'has delegated the values to sample metadata' do
      expect(sample.consent_withdrawn).to eq(sample.sample_metadata.consent_withdrawn)
      expect(sample.date_of_consent_withdrawn).to eq(sample.sample_metadata.date_of_consent_withdrawn)
      expect(sample.user_id_of_consent_withdrawn).to eq(sample.sample_metadata.user_id_of_consent_withdrawn)
    end
  end

  context 'collected by' do
    it 'can be added to a sample' do
      sample = create(:sample, sample_metadata_attributes: { collected_by: 'A Collection Site' })
      expect(sample.sample_metadata.collected_by).to eq('A Collection Site')
    end
  end

  context 'genome size' do
    it 'can be added to a sample' do
      sample = create(:sample, sample_metadata_attributes: { genome_size: 1000 })
      expect(sample.sample_metadata.genome_size).to eq(1000)
    end
  end

  describe '#current_accession_status' do
    let(:sample) { create(:sample) }
    let!(:older_status) { create(:accession_status, sample: sample, created_at: 2.days.ago) }
    let!(:newer_status) { create(:accession_status, sample: sample, created_at: 1.day.ago) }
    let!(:newest_status) { create(:accession_status, sample: sample, created_at: 1.minute.ago) }

    it 'returns the most recent accession status for the sample' do
      expect(sample.current_accession_status).to eq(newest_status)
    end
  end

  describe '#control_formatted' do
    it 'is nil when control is nil' do
      sample = create(:sample, control: nil)
      expect(sample.control_formatted).to be_nil
    end

    it 'shows something useful when control type is positive' do
      sample = create(:sample, control: true, control_type: 'positive')
      expect(sample.control_formatted).to eq 'Yes (positive)'
    end

    it 'shows something useful when control type is negative' do
      sample = create(:sample, control: true, control_type: 'negative')
      expect(sample.control_formatted).to eq 'Yes (negative)'
    end

    it 'shows something useful when control type is unspecified' do
      sample = create(:sample, control: true, control_type: nil)
      expect(sample.control_formatted).to eq 'Yes (type unspecified)'
    end
  end

  context 'control_type validation' do
    subject { build(:sample, control: false, control_type: 'positive') }

    it { is_expected.not_to be_valid }
  end

  describe '#priority', :aggregate_failures do
    it 'will have a default priority of nopriority - 0' do
      expect(build(:sample).priority).to eq('no_priority')
    end

    it 'can have a priority' do
      %w[backlog surveillance priority].each { |priority| expect(build(:sample, priority:).priority).to eq(priority) }
    end
  end

  context 'updating supplier name' do
    let(:sample) { create(:sample) }

    it 'validates that supplier name allows only ASCII characters' do
      expect(sample.sample_metadata.supplier_name).to be_nil
      sample.sample_metadata.supplier_name = 'भारत'
      expect(sample.sample_metadata.save).to be false
    end

    it 'can have the supplier name blanked' do
      expect(sample.sample_metadata.supplier_name).to be_nil
      sample.sample_metadata.update!(supplier_name: 'something')
      expect(sample.sample_metadata.supplier_name).not_to be_nil
      sample.sample_metadata.update!(supplier_name: nil)
      expect(sample.sample_metadata.supplier_name).to be_nil
    end
  end

  context 'compound samples in Cardinal' do
    let!(:compound_sample) { create(:sample) }
    let!(:component_sample1) { create(:sample) }
    let!(:component_sample2) { create(:sample) }

    # let variables are lazy loaded and we always want the relationships to exist
    # even if we don't access the compound sample in the test.
    before do
      compound_sample.update(component_samples: [component_sample1, component_sample2])
      component_sample1.reload
      component_sample2.reload
    end

    it 'compound samples are able to query their component samples' do
      expect(compound_sample.component_samples).to contain_exactly(component_sample1, component_sample2)
    end

    it 'component samples are able to query their compound samples' do
      expect(component_sample1.compound_samples).to contain_exactly(compound_sample)
      expect(component_sample2.compound_samples).to contain_exactly(compound_sample)
    end

    it 'removing a component sample removes both sides of the relationship' do
      compound_sample.component_samples.delete(component_sample2)
      compound_sample.save
      component_sample2.reload

      expect(compound_sample.component_samples).to contain_exactly(component_sample1)
      expect(component_sample1.compound_samples).to contain_exactly(compound_sample)
      expect(component_sample2.compound_samples).to be_empty
    end

    it 'removing a compound sample removes both sides of the relationship' do
      component_sample1.compound_samples.delete(compound_sample)
      compound_sample.reload

      expect(compound_sample.component_samples).to contain_exactly(component_sample2)
      expect(component_sample1.compound_samples).to be_empty
      expect(component_sample2.compound_samples).to contain_exactly(compound_sample)
    end

    it 'component samples can belong to many compound samples' do
      other_compound_sample = create(:sample, component_samples: [component_sample1])
      component_sample1.reload

      expect(other_compound_sample.component_samples).to contain_exactly(component_sample1)
      expect(component_sample1.compound_samples).to contain_exactly(compound_sample, other_compound_sample)
      expect(component_sample2.compound_samples).to contain_exactly(compound_sample)
    end

    context 'changing associations modifies the updated_at time of affected samples' do
      let!(:initial_updated_at) { Time.zone.parse('2012-Mar-16 12:06') }

      before do
        compound_sample.update(updated_at: initial_updated_at)
        component_sample1.update(updated_at: initial_updated_at)
        component_sample2.update(updated_at: initial_updated_at)
      end

      it 'applies when the component_samples association is emptied' do
        compound_sample.component_samples = []

        compound_sample.reload
        component_sample1.reload
        component_sample2.reload

        expect(compound_sample.updated_at).not_to eq initial_updated_at
        expect(component_sample1.updated_at).not_to eq initial_updated_at
        expect(component_sample2.updated_at).not_to eq initial_updated_at
      end

      it 'only applies to samples in the modified association' do
        compound_sample.component_samples = [component_sample2]

        compound_sample.reload
        component_sample1.reload
        component_sample2.reload

        expect(compound_sample.updated_at).not_to eq initial_updated_at
        expect(component_sample1.updated_at).not_to eq initial_updated_at

        # Component sample 2 wasn't modified by the change
        expect(component_sample2.updated_at).to eq initial_updated_at
      end

      it 'applies via the compound_samples association' do
        component_sample2.compound_samples = []

        compound_sample.reload
        component_sample1.reload
        component_sample2.reload

        expect(compound_sample.updated_at).not_to eq initial_updated_at
        expect(component_sample2.updated_at).not_to eq initial_updated_at

        # Component sample 1 wasn't modified by the change
        expect(component_sample1.updated_at).to eq initial_updated_at
      end
    end
  end

  context '(DPL-148) on updating sample metadata' do
    let(:sample) { create(:sample) }

    it 'triggers warehouse update', :warren do
      expect do
        # We try with a valid update
        sample.sample_metadata.update(gender: 'Male')
      end.to change(Warren.handler.messages, :count).from(0)
    end
  end
end
