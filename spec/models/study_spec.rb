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
        a.update_attributes(study: study)
      end
    end
    study.save!

    expect(study).to be_valid
    expect(study.cancelled_requests(request_type)).to eq(3)
    expect(study.completed_requests(request_type)).to eq(4)
    expect(study.completed_requests(request_type_2)).to eq(1)
    expect(study.completed_requests(request_type_3)).to eq(2)
    expect(study.passed_requests(request_type)).to eq(3)
    expect(study.failed_requests(request_type)).to eq(1)
    expect(study.pending_requests(request_type)).to eq(1)
    expect(study.pending_requests(request_type_2)).to eq(0)
    expect(study.pending_requests(request_type_3)).to eq(1)
    expect(study.total_requests(request_type)).to eq(8)

  end

  context 'Role system' do

    let!(:study)          { create(:study, name: 'role test1') }
    let!(:another_study)  { create(:study, name: 'role test2') }

    let!(:user1)          { create(:user) }
    let!(:user2)          { create(:user) }

    before(:each) do
      user1.has_role('owner', study)
      user1.has_role('follower', study)
      user2.has_role('follower', study)
      user2.has_role('manager', study)
    end

    it 'deals with followers' do
      expect(study.followers).to_not be_empty
      expect(study.followers).to include(user1)
      expect(study.followers).to include(user2)
      expect(another_study.followers).to be_empty
    end

    it 'deals with managers' do
      expect(study.managers).to_not be_empty
      expect(study.managers).to_not include(user1)
      expect(study.managers).to include(user2)
      expect(another_study.managers).to be_empty
    end

    it 'deals with owners' do
      expect(study.owners).to_not be_empty
      expect(study.owners).to include(user1)
      expect(study.owners).to_not include(user2)
      expect(another_study.owners).to be_empty
    end
  end

  context '#ethical approval?: ' do

    let!(:study)  { create(:study) }

    context 'when contains human DNA' do
      before(:each) do
        study.study_metadata.contains_human_dna = Study::YES
        study.ethically_approved = false
        study.save!
      end

      context "and isn't contaminated with human DNA and does not contain sample commercially available" do
        before(:each) do
          study.study_metadata.contaminated_human_dna = Study::NO
          study.study_metadata.commercially_available = Study::NO
          study.ethically_approved = false
          study.save!
        end

        it 'be in the awaiting ethical approval list' do
          expect(Study.awaiting_ethical_approval).to include(study)
        end
      end

      context 'and is contaminated with human DNA' do
        before(:each) do
          study.study_metadata.contaminated_human_dna = Study::YES
          study.ethically_approved = nil
          study.save!
        end

        it 'not appear in the awaiting ethical approval list' do
          expect(Study.awaiting_ethical_approval).to_not include(study)
        end
      end
    end

    context 'when needing ethical approval' do
      before(:each) do
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
      before(:each) do
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

      before(:each) do
        study_remove.study_metadata.remove_x_and_autosomes = Study::YES
        study_remove.save!
        study_keep.study_metadata.remove_x_and_autosomes = Study::NO
        study_keep.save!
      end

      it 'show in the filters' do
        expect(Study.with_remove_x_and_autosomes).to include(study_remove)
        expect(Study.with_remove_x_and_autosomes).to_not include(study_keep)
      end
    end

    context 'with check y separation' do

      let!(:study) { create(:study) }

      before(:each) do
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

    context '#unprocessed_submissions?' do

      let!(:study)  { create(:study) }
      let!(:asset)  { create(:sample_tube) }
     
      context 'with submissions still unprocessed' do

        before(:each) do
          FactoryHelp::submission study: study, state: 'building', assets: [asset]
          FactoryHelp::submission study: study, state: 'pending', assets: [asset]
          FactoryHelp::submission study: study, state: 'processing', assets: [asset]
        end

        it 'returns true' do
          expect(study).to be_unprocessed_submissions
        end

      end

      context 'with no submissions unprocessed' do
        before(:each) do
          FactoryHelp::submission study: study, state: 'ready', assets: [asset]
          FactoryHelp::submission study: study, state: 'failed', assets: [asset]
        end

        it 'returns false' do
          expect(study).to_not be_unprocessed_submissions
        end
      end

      context 'with no submissions at all' do
        it 'returns false' do
          expect(study).to_not be_unprocessed_submissions
        end
      end
    end

    context '#deactivate!' do

      let!(:study)          { create(:study) }
      let!(:request_type)   { create(:request_type) }

      before(:each) do
        2.times do
          r = create(:passed_request, request_type: request_type, initial_study_id: study.id)
          r.asset.aliquots.each { |al| al.study = study; al.save! }
        end

        2.times { create(:order, study: study) }
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
        expect(study.requests.all? { |request| request.passed? }).to be_truthy
      end
    end

    context 'policy text' do

      let!(:study)  { create(:managed_study) }


      it 'accept valid urls' do
        expect(study.study_metadata.update_attributes!(dac_policy: 'http://www.example.com')).to be_truthy 
        expect(study.study_metadata.dac_policy).to eq('http://www.example.com') 
      end

      it 'reject free text' do
        expect{ study.study_metadata.update_attributes!(dac_policy: 'Not a URL') }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'reject invalid domains' do
        expect{ study.study_metadata.update_attributes!(dac_policy: 'http://internal.example.com') }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'add http:// before testing a url' do
        expect(study.study_metadata.update_attributes!(dac_policy: 'www.example.com')).to be_truthy
        expect(study.study_metadata.dac_policy).to eq('http://www.example.com')
      end

      it 'not add http for eg. https' do
        expect(study.study_metadata.update_attributes!(dac_policy: 'https://www.example.com')).to be_truthy
        expect(study.study_metadata.dac_policy).to eq('https://www.example.com') 
      end

      it 'require a data access group' do
        study.study_metadata.data_access_group = ''
        expect(study).to_not be_valid
        expect(study.errors['study_metadata.data_access_group']).to include("can't be blank")
      end
    end

    context 'managed study' do

      let!(:study) { create(:managed_study) }
   
      it 'accept valid data access group names' do
        # Valid names contain alphanumerics and underscores. They are limited to 32 characters, and cannot begin with a number
        ['goodname', 'g00dname', 'good_name', '_goodname', 'good-name', 'goodname1  goodname2'].each do |name|
          expect(study.study_metadata.update_attributes!(data_access_group: name)).to be_truthy
          expect(study.study_metadata.data_access_group).to eq(name)
        end
      end

      it 'reject non-alphanumeric data access groups' do
        ['b@dname', '1badname', 'averylongbadnamewouldbebadsowesouldblockit', 'baDname'].each do |name|
          expect { study.study_metadata.update_attributes!(data_access_group: name) }.to raise_error(ActiveRecord::RecordInvalid)
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
        expect(study.update_attributes!(name: 'Short name')).to be_truthy
      end

      it 'rejects names longer than 200 characters' do
        expect { study.update_attributes!(name: 'a' * 201) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'squish whitespace' do
        expect(study.update_attributes!(name: '   Squish   double spaces and flanking whitespace but not double letters ')).to be_truthy 
        expect(study.name).to eq('Squish double spaces and flanking whitespace but not double letters') 
      end
    end

    context '#for_sample_accessioning' do

      let!(:study_1) { create(:open_study) }
      let!(:study_2) { create(:open_study, name: 'Study 2', accession_number: 'ENA123') }
      let!(:study_3) { create(:open_study, name: 'Study 3', accession_number: 'ENA456') }
      let!(:study_4) { create(:managed_study) }
      let!(:study_5) { create(:managed_study, name: 'Study 4', accession_number: 'ENA666') }
      let!(:study_6) { create(:managed_study, name: 'Study 5', accession_number: 'ENA777') }
      let!(:study_7) { create(:managed_study, name: 'Study 6', accession_number: 'ENA888') }
      let!(:study_8) { create(:not_app_study) }

      it 'include studies that adhere to accessioning guidelines' do
        expect(Study.for_sample_accessioning.count).to eq(5)
      end

      it 'not include studies that do not have accession numbers' do
        studies = Study.for_sample_accessioning
        expect(studies).to_not include(study_1)
        expect(studies).to_not include(study_4)
      end

      it 'not include studies that do not have the correct data release timings' do
        expect(study_7.study_metadata.update_attributes!(data_release_timing: Study::DATA_RELEASE_TIMING_NEVER, data_release_prevention_reason: 'data validity', data_release_prevention_approval: 'Yes', data_release_prevention_reason_comment: 'blah, blah, blah')).to be_truthy
        expect(Study.for_sample_accessioning.count).to eq(4)
      end

      it 'not include studies that do not have the correct data release strategies' do
        studies = Study.for_sample_accessioning
        expect(studies).to_not include(study_8)
      end
    end

    context 'accession all samples in study' do
      let!(:accessionable_samples_1)        { create_list(:sample_for_accessioning, 5) }
      let!(:unaccessionable_samples_1)      { create_list(:sample, 3) }
      let!(:accessionable_samples_2)        { create_list(:sample_for_accessioning, 5) }
      let!(:unaccessionable_samples_2)      { create_list(:sample, 3) }
      let!(:open_study)                     { create(:open_study, accession_number: 'ENA123', samples: accessionable_samples_1 + unaccessionable_samples_1) }
      let!(:managed_study)                  { create(:open_study, accession_number: 'ENA123', samples: accessionable_samples_2 + unaccessionable_samples_2) }
      let!(:unaccessionable_study)          { create(:open_study, samples: accessionable_samples + unaccessionable_samples) }

      it 'accessions all of the samples that are accessionable' do
        open_study.accession_all_samples
        expect(accessionable_samples_1.all? { |sample| sample.sample_metadata.sample_ebi_accession_number.present?} ).to be_truthy

        managed_study.accession_all_samples
        expect(accessionable_samples_2.all? { |sample| sample.sample_metadata.sample_ebi_accession_number.present?} ).to be_truthy
      end

      it 'does not accession any samples that are unaccessionable' do
        open_study.accession_all_samples
        expect(unaccessionable_samples_1.all? { |sample| sample.sample_metadata.sample_ebi_accession_number.nil?} ).to be_truthy

        managed_study.accession_all_samples
        expect(unaccessionable_samples_2.all? { |sample| sample.sample_metadata.sample_ebi_accession_number.nil?} ).to be_truthy
      end

      it 'will not attempt to accession any samples belonging to a study that does not have an accession number' do
        expect(accessionable_samples_1.first).to_not receive(:accession)
        open_study.accession_all_samples
        expect(accessionable_samples_1.all? { |sample| sample.sample_metadata.sample_ebi_accession_number.nil?} ).to be_truthy

        expect(accessionable_samples_2.first).to_not receive(:accession)
        managed_study.accession_all_samples
        expect(accessionable_samples_2.all? { |sample| sample.sample_metadata.sample_ebi_accession_number.nil?} ).to be_truthy

      end

    end


  end
end