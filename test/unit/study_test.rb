# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'test_helper'

class StudyTest < ActiveSupport::TestCase
  context 'Study' do
    should belong_to :user

    should have_many :samples # , :through => :study_samples

    context 'Request' do
      setup do
        @study = create :study
        @request_type    = create :request_type
        @request_type_2  = create :request_type, name: 'request_type_2', key: 'request_type_2'
        @request_type_3  = create :request_type, name: 'request_type_3', key: 'request_type_3'
        requests = []
        # Cancelled
        3.times do
          requests << (create :cancelled_request, study: @study, request_type: @request_type)
        end

        # Failed
        requests << (create :failed_request, study: @study, request_type: @request_type)
        # Passed
        3.times do
          requests << (create :passed_request, study: @study, request_type: @request_type)
        end
        requests << (create :passed_request, study: @study, request_type: @request_type_2)
        requests << (create :passed_request, study: @study, request_type: @request_type_3)
        requests << (create :passed_request, study: @study, request_type: @request_type_3)
        # Pending
        requests << (create :pending_request, study: @study, request_type: @request_type)
        requests << (create :pending_request, study: @study, request_type: @request_type_3)

        # we have to hack t
        requests.each do |request|
          request.asset.aliquots.each do |a|
            a.update_attributes(study: @study)
          end
        end
        @study.save!
      end

      should 'Calculate correctly and be valid' do
        assert @study.valid?
        assert_equal 3, @study.cancelled_requests(@request_type)
        assert_equal 4, @study.completed_requests(@request_type)
        assert_equal 1, @study.completed_requests(@request_type_2)
        assert_equal 2, @study.completed_requests(@request_type_3)
        assert_equal 3, @study.passed_requests(@request_type)
        assert_equal 1, @study.failed_requests(@request_type)
        assert_equal 1, @study.pending_requests(@request_type)
        assert_equal 0, @study.pending_requests(@request_type_2)
        assert_equal 1, @study.pending_requests(@request_type_3)
        assert_equal 8, @study.total_requests(@request_type)
      end
    end

    context 'Role system' do
      setup do
        @study = create :study, name: 'role test1'
        @another_study = create :study, name: 'role test2'

        @user1 = create :user
        @user2 = create :user

        @user1.has_role('owner', @study)
        @user1.has_role('follower', @study)
        @user2.has_role('follower', @study)
        @user2.has_role('manager', @study)
      end

      should 'deal with followers' do
        refute @study.followers.empty?
        assert @study.followers.include?(@user1)
        assert @study.followers.include?(@user2)
        assert @another_study.followers.empty?
      end

      should 'deal with managers' do
        refute @study.managers.empty?
        refute @study.managers.include?(@user1)
        assert @study.managers.include?(@user2)
        assert @another_study.managers.empty?
      end

      should 'deal with owners' do
        refute @study.owners.empty?
        assert @study.owners.include?(@user1)
        refute @study.owners.include?(@user2)
        assert @another_study.owners.empty?
      end
    end

    context '#ethical approval?: ' do
      setup do
        @study = create :study
      end

      context 'when contains human DNA' do
        setup do
          @study.study_metadata.contains_human_dna = Study::YES
          @study.ethically_approved = false
          @study.save!
        end

        context "and isn't contaminated with human DNA and does not contain sample commercially available" do
          setup do
            @study.study_metadata.contaminated_human_dna = Study::NO
            @study.study_metadata.commercially_available = Study::NO
            @study.ethically_approved = false
            @study.save!
          end
          should 'be in the awaiting ethical approval list' do
            assert_contains(Study.awaiting_ethical_approval, @study)
          end
        end

        context 'and is contaminated with human DNA' do
          setup do
            @study.study_metadata.contaminated_human_dna = Study::YES
            @study.ethically_approved = nil
            @study.save!
          end
          should 'not appear in the awaiting ethical approval list' do
            assert_does_not_contain(Study.awaiting_ethical_approval, @study)
          end
        end
      end

      context 'when needing ethical approval' do
        setup do
          @study.study_metadata.contains_human_dna = Study::YES
          @study.study_metadata.contaminated_human_dna = Study::NO
          @study.study_metadata.commercially_available = Study::NO
        end

        should 'not be set to not applicable' do
          @study.ethically_approved = nil
          @study.valid?
          assert @study.ethically_approved == false
        end

        should 'be valid with true' do
          @study.ethically_approved = true
          assert @study.valid?
        end

        should 'be valid with false' do
          @study.ethically_approved = false
          assert @study.valid?
        end
      end

      context 'when not needing ethical approval' do
        setup do
          @study.study_metadata.contains_human_dna = Study::YES
          @study.study_metadata.contaminated_human_dna = Study::YES
          @study.study_metadata.commercially_available = Study::NO
        end

        should 'be valid with not applicable' do
          @study.ethically_approved = nil
          assert @study.valid?
        end

        should 'be valid with true' do
          @study.ethically_approved = true
          assert @study.valid?
        end

        should 'not be set to false' do
          @study.ethically_approved = false
          @study.valid?
          assert @study.ethically_approved == nil
        end
      end
    end

    context 'which needs x and autosomal DNA removed' do
      setup do
        @study_remove = create :study
        @study_remove.study_metadata.remove_x_and_autosomes = Study::YES
        @study_remove.save!
        @study_keep = create :study
        @study_keep.study_metadata.remove_x_and_autosomes = Study::NO
        @study_keep.save!
      end

      should 'show in the filters' do
        assert Study.with_remove_x_and_autosomes.include?(@study_remove)
        refute Study.with_remove_x_and_autosomes.include?(@study_keep)
      end
    end

    context 'with check y separation' do
      setup do
        @study = create :study
        @study.study_metadata.separate_y_chromosome_data = true
      end

      should 'be valid when we are sane' do
        @study.study_metadata.remove_x_and_autosomes = Study::NO
        assert @study.save!
      end

      should 'be invalid when we do something silly' do
        @study.study_metadata.remove_x_and_autosomes = Study::YES
        assert_raise ActiveRecord::RecordInvalid do
          @study.save!
        end
      end
    end

    context '#unprocessed_submissions?' do
      setup do
        @study = create :study
        @asset = create :sample_tube
      end
      context 'with submissions still unprocessed' do
        setup do
          FactoryHelp::submission study: @study, state: 'building', assets: [@asset]
          FactoryHelp::submission study: @study, state: 'pending', assets: [@asset]
          FactoryHelp::submission study: @study, state: 'processing', assets: [@asset]
        end
        should 'return true' do
          assert @study.unprocessed_submissions?
        end
      end
      context 'with no submissions unprocessed' do
        setup do
          FactoryHelp::submission study: @study, state: 'ready', assets: [@asset]
          FactoryHelp::submission study: @study, state: 'failed', assets: [@asset]
        end
        should 'return false' do
          refute @study.unprocessed_submissions?
        end
      end
      context 'with no submissions at all' do
        should 'return false' do
          refute @study.unprocessed_submissions?
        end
      end
    end

    context '#deactivate!' do
      setup do
        @study, @request_type = create(:study), create(:request_type)
        2.times do
          r = create(:passed_request, request_type: @request_type, initial_study_id: @study.id)
          r.asset.aliquots.each { |al| al.study = @study; al.save! }
        end
        2.times { create(:order, study: @study) }
        @study.projects.each do |project|
          project.enforce_quotas = true
        end
        @study.save!

        # All that has happened to this point is just prelude
        @study.deactivate!
      end

      should 'be inactive' do
        assert @study.inactive?
      end

      should 'not cancel any associated requests' do
        assert @study.requests.all? { |request| request.passed? }
      end
    end

    context 'policy text' do
      setup do
        @study = create(:managed_study)
      end

      should 'accept valid urls' do
        assert @study.study_metadata.update_attributes!(dac_policy: 'http://www.example.com')
        assert_equal 'http://www.example.com', @study.study_metadata.dac_policy
      end

      should 'reject free text' do
        assert_raise ActiveRecord::RecordInvalid do
         @study.study_metadata.update_attributes!(dac_policy: 'Not a URL')
        end
      end

      should 'reject invalid domains' do
        # In this context invalid domains refers to those on internal domains inaccessible outside the unit
        assert_raise ActiveRecord::RecordInvalid do
          @study.study_metadata.update_attributes!(dac_policy: 'http://internal.example.com')
        end
      end

      should 'add http:// before testing a url' do
        assert @study.study_metadata.update_attributes!(dac_policy: 'www.example.com')
        assert_equal 'http://www.example.com', @study.study_metadata.dac_policy
      end

      should 'not add http for eg. https' do
        assert @study.study_metadata.update_attributes!(dac_policy: 'https://www.example.com')
        assert_equal 'https://www.example.com', @study.study_metadata.dac_policy
      end

      should 'require a data access group' do
        @study.study_metadata.data_access_group = ''
        refute @study.valid?
        assert_includes @study.errors['study_metadata.data_access_group'], "can't be blank"
      end
    end

    context 'policy text' do
      setup do
        @study = create :managed_study
      end

      should 'accept valid data access group names' do
        # Valid names contain alphanumerics and underscores. They are limited to 32 characters, and cannot begin with a number
        ['goodname', 'g00dname', 'good_name', '_goodname', 'good-name', 'goodname1  goodname2'].each do |name|
          assert @study.study_metadata.update_attributes!(data_access_group: name)
          assert_equal name, @study.study_metadata.data_access_group
        end
      end

      should 'reject non-alphanumeric data access groups' do
        ['b@dname', '1badname', 'averylongbadnamewouldbebadsowesouldblockit', 'baDname'].each do |name|
          assert_raise ActiveRecord::RecordInvalid do
            @study.study_metadata.update_attributes!(data_access_group: name)
          end
        end
      end
    end

    context 'non-managed study' do
      setup do
        @study = build :study
      end

      should 'should not require a data access group' do
        @study.study_metadata.data_access_group = ''
        assert @study.valid?
      end
    end

    context 'study name' do
      setup do
        @study = create :study
      end

      should 'accept names shorter than 200 characters' do
        assert @study.update_attributes!(name: 'Short name')
      end

      should 'reject names longer than 200 characters' do
        assert_raise(ActiveRecord::RecordInvalid) do
          @study.update_attributes!(name: 'a' * 201)
        end
      end

      should ' squish whitespace' do
        assert @study.update_attributes!(name: '   Squish   double spaces and flanking whitespace but not double letters ')
        assert_equal 'Squish double spaces and flanking whitespace but not double letters', @study.name
      end
    end

    context '#for_sample_accessioning' do
      attr_reader :study_1, :study_4, :study_7, :study_8

      setup do
        @study_1 = create(:open_study)
        @study_2 = create(:open_study, name: 'Study 2', accession_number: 'ENA123')
        @study_3 = create(:open_study, name: 'Study 3', accession_number: 'ENA456')
        @study_4 = create(:managed_study)
        @study_5 = create(:managed_study, name: 'Study 4', accession_number: 'ENA666')
        @study_6 = create(:managed_study, name: 'Study 5', accession_number: 'ENA777')
        @study_7 = create(:managed_study, name: 'Study 6', accession_number: 'ENA888')
        @study_8 = create(:not_app_study)
      end

      should 'include studies that adhere to accessioning guidelines' do
        assert_equal(5, Study.for_sample_accessioning.count)
      end

      should 'not include studies that do not have accession numbers' do
        studies = Study.for_sample_accessioning
        refute studies.include?(study_1)
        refute studies.include?(study_4)
      end

      should 'not include studies that do not have the correct data release timings' do
        study_7.study_metadata.update_attributes!(data_release_timing: Study::DATA_RELEASE_TIMING_NEVER, data_release_prevention_reason: 'data validity', data_release_prevention_approval: 'Yes', data_release_prevention_reason_comment: 'blah, blah, blah')
        assert_equal(4, Study.for_sample_accessioning.count)
      end

      should 'not include studies that do not have the correct data release strategies' do
        studies = Study.for_sample_accessioning
        refute studies.include?(study_8)
      end
    end
  end
end
