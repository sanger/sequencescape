# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Study, type: :model do
  it 'request calculates correctly and is valid' do
    study = create(:study)
    request_type = create(:request_type)
    request_type_2 = create(:request_type, name: 'request_type_2', key: 'request_type_2')
    request_type_3 = create(:request_type, name: 'request_type_3', key: 'request_type_3')

    requests = [].tap do |r|
      # Cancelled
      3.times do
        r << (create :cancelled_request, study: study, request_type: request_type)
      end

      # Failed
      r << (create :failed_request, study: study, request_type: request_type)

      # Passed
      3.times do
        r << (create :passed_request, study: study, request_type: request_type)
      end

      r << (create :passed_request, study: study, request_type: request_type_2)
      r << (create :passed_request, study: study, request_type: request_type_3)
      r << (create :passed_request, study: study, request_type: request_type_3)

      # Pending
      r << (create :pending_request, study: study, request_type: request_type)
      r << (create :pending_request, study: study, request_type: request_type_3)
    end

    # we have to hack t
    requests.each do |request|
      request.asset.aliquots.each do |a|
        a.update(study: study)
      end
    end
    study.save!

    expect(study).to be_valid
    # New tests here?
  end

  it 'validates uniqueness of name (case sensitive)' do
    study_1 = create :study, name: 'Study_name'
    study_2 = build :study, name: 'Study_name'
    study_3 = build :study, name: 'Study_NAME'
    expect(study_2.valid?).to be false
    expect(study_2.errors.messages.length).to eq 1
    expect(study_2.errors.full_messages).to include 'Name has already been taken'
    expect(study_3.valid?).to be false
    expect(study_2.errors.messages.length).to eq 1
    expect(study_3.errors.full_messages).to include 'Name has already been taken'
  end

  context 'Role system' do
    let!(:study)          { create(:study, name: 'role test1') }
    let!(:another_study)  { create(:study, name: 'role test2') }

    let!(:user1)          { create(:user) }
    let!(:user2)          { create(:user) }

    before do
      user1.has_role('owner', study)
      user1.has_role('follower', study)
      user2.has_role('follower', study)
      user2.has_role('manager', study)
    end

    it 'deals with followers' do
      expect(study.followers).not_to be_empty
      expect(study.followers).to include(user1)
      expect(study.followers).to include(user2)
      expect(another_study.followers).to be_empty
    end

    it 'deals with managers' do
      expect(study.managers).not_to be_empty
      expect(study.managers).not_to include(user1)
      expect(study.managers).to include(user2)
      expect(another_study.managers).to be_empty
    end

    it 'deals with owners' do
      expect(study.owners).not_to be_empty
      expect(study.owners).to include(user1)
      expect(study.owners).not_to include(user2)
      expect(another_study.owners).to be_empty
    end
  end

  describe '#ethical approval?: ' do
    let!(:study)  { create(:study) }

    context 'when contains human DNA' do
      before do
        study.study_metadata.contains_human_dna = Study::YES
        study.ethically_approved = false
        study.save!
      end

      context "and isn't contaminated with human DNA and does not contain sample commercially available" do
        before do
          study.study_metadata.contaminated_human_dna = Study::NO
          study.study_metadata.commercially_available = Study::NO
          study.ethically_approved = false
          study.save!
        end

        it 'be in the awaiting ethical approval list' do
          expect(described_class.awaiting_ethical_approval).to include(study)
        end
      end

      context 'and is contaminated with human DNA' do
        before do
          study.study_metadata.contaminated_human_dna = Study::YES
          study.ethically_approved = nil
          study.save!
        end

        it 'not appear in the awaiting ethical approval list' do
          expect(described_class.awaiting_ethical_approval).not_to include(study)
        end
      end
    end

    context 'when needing ethical approval' do
      before do
        study.study_metadata.contains_human_dna = Study::YES
        study.study_metadata.contaminated_human_dna = Study::NO
        study.study_metadata.commercially_available = Study::NO
      end

      it 'not be set to not applicable' do
        study.ethically_approved = nil
        study.valid?
        expect(study.ethically_approved).to be_falsey
      end

      it 'be valid with true' do
        study.ethically_approved = true
        expect(study).to be_valid
      end

      it 'be valid with false' do
        study.ethically_approved = false
        expect(study).to be_valid
      end
    end

    context 'when not needing ethical approval' do
      before do
        study.study_metadata.contains_human_dna = Study::YES
        study.study_metadata.contaminated_human_dna = Study::YES
        study.study_metadata.commercially_available = Study::NO
      end

      it 'be valid with not applicable' do
        study.ethically_approved = nil
        expect(study).to be_valid
      end

      it 'be valid with true' do
        study.ethically_approved = true
        expect(study).to be_valid
      end

      it 'not be set to false' do
        study.ethically_approved = false
        study.valid?
        expect(study.ethically_approved).to be_nil
      end
    end

    context 'which needs x and autosomal DNA removed' do
      let!(:study_remove) { create(:study) }
      let!(:study_keep)   { create(:study) }

      before do
        study_remove.study_metadata.remove_x_and_autosomes = Study::YES
        study_remove.save!
        study_keep.study_metadata.remove_x_and_autosomes = Study::NO
        study_keep.save!
      end

      it 'show in the filters' do
        expect(described_class.with_remove_x_and_autosomes).to include(study_remove)
        expect(described_class.with_remove_x_and_autosomes).not_to include(study_keep)
      end
    end

    context 'with check y separation' do
      let!(:study) { create(:study) }

      before do
        study.study_metadata.separate_y_chromosome_data = true
      end

      it 'will be valid when we are sane' do
        study.study_metadata.remove_x_and_autosomes = Study::NO
        expect(study.save!).to be_truthy
      end

      it 'will be invalid when we do something silly' do
        study.study_metadata.remove_x_and_autosomes = Study::YES
        expect { study.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe '#unprocessed_submissions?' do
      let!(:study)  { create(:study) }
      let!(:asset)  { create(:sample_tube) }

      context 'with submissions still unprocessed' do
        before do
          FactoryHelp::submission study: study, state: 'building', assets: [asset]
          FactoryHelp::submission study: study, state: 'pending', assets: [asset]
          FactoryHelp::submission study: study, state: 'processing', assets: [asset]
        end

        it 'returns true' do
          expect(study).to be_unprocessed_submissions
        end
      end

      context 'with no submissions unprocessed' do
        before do
          FactoryHelp::submission study: study, state: 'ready', assets: [asset]
          FactoryHelp::submission study: study, state: 'failed', assets: [asset]
        end

        it 'returns false' do
          expect(study).not_to be_unprocessed_submissions
        end
      end

      context 'with no submissions at all' do
        it 'returns false' do
          expect(study).not_to be_unprocessed_submissions
        end
      end
    end

    describe '#deactivate!' do
      let!(:study)          { create(:study) }
      let!(:request_type)   { create(:request_type) }

      before do
        2.times do
          r = create(:passed_request, request_type: request_type, initial_study_id: study.id)
          r.asset.aliquots.each { |al| al.study = study; al.save! }
        end

        create_list(:order, 2, study: study)
        study.projects.each do |project|
          project.enforce_quotas = true
        end
        study.save!

        # All that has happened to this point is just prelude
        study.deactivate!
      end

      it 'be inactive' do
        expect(study).to be_inactive
      end

      it 'not cancel any associated requests' do
        expect(study.requests).to be_all(&:passed?)
      end
    end

    context 'policy text' do
      let!(:study)  { create(:managed_study) }

      it 'accept valid urls' do
        expect(study.study_metadata.update!(dac_policy: 'http://www.example.com')).to be_truthy
        expect(study.study_metadata.dac_policy).to eq('http://www.example.com')
      end

      it 'reject free text' do
        expect { study.study_metadata.update!(dac_policy: 'Not a URL') }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'reject invalid domains' do
        expect { study.study_metadata.update!(dac_policy: 'http://internal.example.com') }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'add http:// before testing a url' do
        expect(study.study_metadata.update!(dac_policy: 'www.example.com')).to be_truthy
        expect(study.study_metadata.dac_policy).to eq('http://www.example.com')
      end

      it 'not add http for eg. https' do
        expect(study.study_metadata.update!(dac_policy: 'https://www.example.com')).to be_truthy
        expect(study.study_metadata.dac_policy).to eq('https://www.example.com')
      end

      it 'require a data access group' do
        study.study_metadata.data_access_group = ''
        expect(study).not_to be_valid
        expect(study.errors['study_metadata.data_access_group']).to include("can't be blank")
      end
    end

    context 'managed study' do
      let!(:study) { create(:managed_study) }

      it 'accept valid data access group names' do
        # Valid names contain alphanumerics and underscores. They are limited to 32 characters, and cannot begin with a number
        ['goodname', 'g00dname', 'good_name', '_goodname', 'good-name', 'goodname1  goodname2'].each do |name|
          expect(study.study_metadata.update!(data_access_group: name)).to be_truthy
          expect(study.study_metadata.data_access_group).to eq(name)
        end
      end

      it 'reject non-alphanumeric data access groups' do
        ['b@dname', '1badname', 'averylongbadnamewouldbebadsowesouldblockit', 'baDname'].each do |name|
          expect { study.study_metadata.update!(data_access_group: name) }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'non-managed study' do
      let(:study) { build(:study) }

      it 'does not require a data access group' do
        study.study_metadata.data_access_group = ''
        expect(study).to be_valid
      end
    end

    context 'study name' do
      let!(:study) { create(:study) }

      it 'accepts names shorter than 200 characters' do
        expect(study.update!(name: 'Short name')).to be_truthy
      end

      it 'rejects names longer than 200 characters' do
        expect { study.update!(name: 'a' * 201) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'squish whitespace' do
        expect(study.update!(name: '   Squish   double spaces and flanking whitespace but not double letters ')).to be_truthy
        expect(study.name).to eq('Squish double spaces and flanking whitespace but not double letters')
      end
    end

    describe '#for_sample_accessioning' do
      let!(:study_1) { create(:open_study) }
      let!(:study_2) { create(:open_study, name: 'Study 2', accession_number: 'ENA123') }
      let!(:study_3) { create(:open_study, name: 'Study 3', accession_number: 'ENA456') }
      let!(:study_4) { create(:managed_study) }
      let!(:study_5) { create(:managed_study, name: 'Study 4', accession_number: 'ENA666') }
      let!(:study_6) { create(:managed_study, name: 'Study 5', accession_number: 'ENA777') }
      let!(:study_7) { create(:managed_study, name: 'Study 6', accession_number: 'ENA888') }
      let!(:study_8) { create(:not_app_study) }

      it 'include studies that adhere to accessioning guidelines' do
        expect(described_class.for_sample_accessioning.count).to eq(5)
      end

      it 'not include studies that do not have accession numbers' do
        studies = described_class.for_sample_accessioning
        expect(studies).not_to include(study_1)
        expect(studies).not_to include(study_4)
      end

      it 'not include studies that do not have the correct data release timings' do
        expect(study_7.study_metadata.update!(data_release_timing: Study::DATA_RELEASE_TIMING_NEVER, data_release_prevention_reason: 'data validity', data_release_prevention_approval: 'Yes',
                                              data_release_prevention_reason_comment: 'blah, blah, blah')).to be_truthy
        expect(described_class.for_sample_accessioning.count).to eq(4)
      end

      it 'not include studies that do not have the correct data release strategies' do
        studies = described_class.for_sample_accessioning
        expect(studies).not_to include(study_8)
      end
    end

    describe '#each_well_for_qc_report_in_batches' do
      let!(:study) { create(:study) }
      let(:purpose_1) { PlatePurpose.stock_plate_purpose }
      let(:purpose_2) { create :plate_purpose }
      let(:purpose_3) { create :plate_purpose }
      let(:purpose_4) { create :plate_purpose }
      let!(:well_1) { create(:well_for_qc_report, study: study, plate: create(:plate, plate_purpose: purpose_1)) }
      let!(:well_2) { create(:well_for_qc_report, study: study, plate: create(:plate, plate_purpose: purpose_2)) }
      let!(:well_3) { create(:well_for_qc_report, study: study, plate: create(:plate, plate_purpose: purpose_3)) }
      let!(:well_4) { create(:well_for_qc_report, study: study, plate: create(:plate, plate_purpose: purpose_4)) }

      it 'will limit by stock plate purposes if there are no plate purposes' do
        wells_count = 0
        study.each_well_for_qc_report_in_batches(false, 'Bespoke RNA') { |wells| wells_count += wells.length }
        expect(wells_count).to eq(1)
      end

      it 'will limit by passed plates purposes' do
        wells_count = 0
        study.each_well_for_qc_report_in_batches(false, 'Bespoke RNA', [purpose_2.name, purpose_3.name, purpose_4.name]) { |wells| wells_count += wells.length }
        expect(wells_count).to eq(3)

        wells_count = 0
        study.each_well_for_qc_report_in_batches(false, 'Bespoke RNA', [purpose_2.name, purpose_3.name]) { |wells| wells_count += wells.length }
        expect(wells_count).to eq(2)
      end
    end
  end

  describe '#mailing_list_of_managers' do
    subject { study.mailing_list_of_managers }

    let(:study) { create :study }

    context 'with a manger' do
      before { create :manager, authorizable: study, email: 'manager@example.com' }

      it { is_expected.to eq ['manager@example.com'] }
    end

    context 'without a manger' do
      before { create :admin }

      it { is_expected.to eq ['ssr@example.com'] }
    end
  end

  describe 'metadata' do
    let(:metadata) do
      {
        prelim_id: 'A1234',
        study_description: 'A particularly good study.',
        contaminated_human_dna: 'Yes',
        remove_x_and_autosomes: 'No',
        separate_y_chromosome_data: true,
        study_project_id: '1',
        study_abstract: 'blah blah blah',
        study_study_title: 'Study Title',
        study_ebi_accession_number: 'EBI123456',
        study_sra_hold: 'Hold',
        contains_human_dna: 'Yes',
        commercially_available: 'Yes',
        study_name_abbreviation: 'WTCCC',
        data_release_strategy: 'open',
        data_release_standard_agreement: 'Yes',
        data_release_timing: 'standard',
        data_release_delay_reason: 'phd study',
        data_release_delay_period: '3 months',
        bam: true,
        data_release_delay_other_comment: 'Data Release delay other comment',
        data_release_delay_reason_comment: 'Data Release delay reason comment',
        dac_policy: configatron.default_policy_text,
        dac_policy_title: configatron.default_policy_title,
        ega_dac_accession_number: 'DAC123456',
        ega_policy_accession_number: 'POL123456',
        array_express_accession_number: 'ARR123456',
        data_release_delay_approval: 'Yes',
        data_release_prevention_reason: 'data validity',
        data_release_prevention_approval: 'Yes',
        data_release_prevention_reason_comment: 'Data Release prevention reason comment',
        data_access_group: 'something',
        snp_study_id: 123456,
        snp_parent_study_id: 123456,
        number_of_gigabases_per_sample: 6,
        hmdmc_approval_number: 'HDMC123456',
        s3_email_list: 'aa1@sanger.ac.uk;aa2@sanger.ac.uk',
        data_deletion_period: '3 months'
      }
    end

    context 'standard data release' do
      let(:study) { create(:study, study_metadata: create(:study_metadata, metadata)) }

      it 'will have a prelim_id' do
        expect(study.study_metadata.prelim_id).to eq(metadata[:prelim_id])
      end

      it 'will have a study_description' do
        expect(study.study_metadata.study_description).to eq(metadata[:study_description])
      end

      it 'will have a contaminated_human_dna' do
        expect(study.study_metadata.contaminated_human_dna).to eq(metadata[:contaminated_human_dna])
      end

      it 'will have a remove_x_and_autosomes' do
        expect(study.study_metadata.remove_x_and_autosomes).to eq(metadata[:remove_x_and_autosomes])
      end

      it 'will have a separate_y_chromosome_data' do
        expect(study.study_metadata.separate_y_chromosome_data).to eq(metadata[:separate_y_chromosome_data])
      end

      it 'will have a study_project_id' do
        expect(study.study_metadata.study_project_id).to eq(metadata[:study_project_id])
      end

      it 'will have a study_abstract' do
        expect(study.study_metadata.study_abstract).to eq(metadata[:study_abstract])
      end

      it 'will have a study_study_title' do
        expect(study.study_metadata.study_study_title).to eq(metadata[:study_study_title])
      end

      it 'will have a study_ebi_accession_number' do
        expect(study.study_metadata.study_ebi_accession_number).to eq(metadata[:study_ebi_accession_number])
      end

      it 'will have a study_sra_hold' do
        expect(study.study_metadata.study_sra_hold).to eq(metadata[:study_sra_hold])
      end

      it 'will have a contains_human_dna' do
        expect(study.study_metadata.contains_human_dna).to eq(metadata[:contains_human_dna])
      end

      it 'will have a commercially_available' do
        expect(study.study_metadata.commercially_available).to eq(metadata[:commercially_available])
      end

      it 'will have a study_name_abbreviation' do
        expect(study.study_metadata.study_name_abbreviation).to eq(metadata[:study_name_abbreviation])
      end

      it 'will have a data_release_strategy' do
        expect(study.study_metadata.data_release_strategy).to eq(metadata[:data_release_strategy])
      end

      it 'will have a data_release_timing' do
        expect(study.study_metadata.data_release_timing).to eq(metadata[:data_release_timing])
      end

      it 'will have a bam' do
        expect(study.study_metadata.bam).to eq(metadata[:bam])
      end

      it 'will have a ega_dac_accession_number' do
        expect(study.study_metadata.ega_dac_accession_number).to eq(metadata[:ega_dac_accession_number])
      end

      it 'will have a ega_policy_accession_number' do
        expect(study.study_metadata.ega_policy_accession_number).to eq(metadata[:ega_policy_accession_number])
      end

      it 'will have a array_express_accession_number' do
        expect(study.study_metadata.array_express_accession_number).to eq(metadata[:array_express_accession_number])
      end

      it 'will have a data_access_group' do
        expect(study.study_metadata.data_access_group).to eq(metadata[:data_access_group])
      end

      it 'will have a snp_study_id' do
        expect(study.study_metadata.snp_study_id).to eq(metadata[:snp_study_id])
      end

      it 'will have a snp_parent_study_id' do
        expect(study.study_metadata.snp_parent_study_id).to eq(metadata[:snp_parent_study_id])
      end

      it 'will have a number_of_gigabases_per_sample' do
        expect(study.study_metadata.number_of_gigabases_per_sample).to eq(metadata[:number_of_gigabases_per_sample])
      end

      it 'will have a hmdmc_approval_number' do
        expect(study.study_metadata.hmdmc_approval_number).to eq(metadata[:hmdmc_approval_number])
      end

      it 'will have a s3_email_list' do
        expect(study.study_metadata.s3_email_list).to eq(metadata[:s3_email_list])
      end

      it 'will have a data_deletion_period' do
        expect(study.study_metadata.data_deletion_period).to eq(metadata[:data_deletion_period])
      end

      it 'must have a study type' do
        expect(study.study_metadata.study_type).not_to be_nil
      end

      it 'must have a data release study type' do
        expect(study.study_metadata.data_release_study_type).not_to be_nil
      end

      it 'must have a reference genome' do
        expect(study.study_metadata.reference_genome).not_to be_nil
      end

      it 'must have a faculty sponsor' do
        expect(study.study_metadata.faculty_sponsor).not_to be_nil
      end

      it 'must have a program' do
        expect(study.study_metadata.program).not_to be_nil
      end
    end

    context 'delayed release' do
      let(:study) { create(:study, study_metadata: create(:study_metadata, metadata.merge(data_release_timing: 'delayed'))) }

      it 'will have a data_release_delay_reason' do
        expect(study.study_metadata.data_release_delay_reason).to eq(metadata[:data_release_delay_reason])
      end

      it 'will have a data_release_delay_period' do
        expect(study.study_metadata.data_release_delay_period).to eq(metadata[:data_release_delay_period])
      end
    end

    context 'managed study' do
      let(:study) { create(:study, study_metadata: create(:study_metadata, metadata.merge(data_release_strategy: 'managed'))) }

      it 'will have a data_release_standard_agreement' do
        expect(study.study_metadata.data_release_standard_agreement).to eq(metadata[:data_release_standard_agreement])
      end

      it 'will have a dac_policy' do
        expect(study.study_metadata.dac_policy).to eq(metadata[:dac_policy])
      end

      it 'will have a dac_policy_title' do
        expect(study.study_metadata.dac_policy_title).to eq(metadata[:dac_policy_title])
      end
    end

    context 'delayed for other reasons' do
      let(:study) { create(:study, study_metadata: create(:study_metadata, metadata.merge(data_release_timing: 'delayed', data_release_delay_reason: 'other'))) }

      it 'will have a data_release_delay_other_comment' do
        expect(study.study_metadata.data_release_delay_other_comment).to eq(metadata[:data_release_delay_other_comment])
      end

      it 'will have a data_release_delay_reason_comment' do
        expect(study.study_metadata.data_release_delay_reason_comment).to eq(metadata[:data_release_delay_reason_comment])
      end
    end

    context 'delayed for long time' do
      let(:study) { create(:study, study_metadata: create(:study_metadata, metadata.merge(data_release_timing: 'delayed', data_release_delay_period: '6 months'))) }

      it 'will have a data_release_delay_approval' do
        expect(study.study_metadata.data_release_delay_approval).to eq(metadata[:data_release_delay_approval])
      end
    end

    context 'never released' do
      let(:study) { create(:study, study_metadata: create(:study_metadata, metadata.merge(data_release_timing: 'never'))) }

      it 'will have a data_release_prevention_reason' do
        expect(study.study_metadata.data_release_prevention_reason).to eq(metadata[:data_release_prevention_reason])
      end

      it 'will have a data_release_prevention_approval' do
        expect(study.study_metadata.data_release_prevention_approval).to eq(metadata[:data_release_prevention_approval])
      end

      it 'will have a data_release_prevention_reason_comment' do
        expect(study.study_metadata.data_release_prevention_reason_comment).to eq(metadata[:data_release_prevention_reason_comment])
      end
    end
  end
end
