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
  end
end