# frozen_string_literal: true

require 'cancan/matchers'
# Disable the aggregate example cop as these tests are fast, and it doesn't
# especially help readability
RSpec.describe Ability do
  subject(:ability) { described_class.new(user) }

  let(:user) { nil }

  let(:global_permissions) do
    # This is a list of all possible permissions. It is used to generate the tests.
    # We check each permission in turn. If it is in the granted_permissions hash,
    # we check it is granted, otherwise we check it is forbidden.
    {
      AssetGroup => %i[create edit read delete new],
      BaitLibrary => %i[create edit read delete],
      BaitLibrary::Supplier => %i[create edit read delete],
      BaitLibraryType => %i[create edit read delete],
      BarcodePrinter => %i[create edit read delete],
      Batch => %i[rollback edit sample_prep_worksheet print verify],
      Comment => %i[create delete new],
      CustomText => %i[create edit read delete],
      Delayed::Job => %i[read],
      Document => %i[delete],
      FacultySponsor => %i[create edit read delete],
      GelsController => %i[create edit read delete],
      Labware => %i[rename change_purpose edit read],
      Order => %i[create new],
      Pipeline => %i[activate deactivate update_priority],
      Plate => %i[convert_to_tube],
      PlatePurpose => %i[create new edit read delete],
      PlateTemplate => %i[read create edit delete],
      PrimerPanel => %i[create edit read delete],
      Program => %i[create edit read delete],
      Project => %i[administer edit create create_submission read delete],
      Purpose => %i[create edit read delete new],
      QcDecision => %i[create new],
      Receptacle => %i[edit close create read delete],
      ReferenceGenome => %i[create edit read delete],
      Request => %i[
        create_additional
        copy
        cancel
        change_priority
        see_previously_failed
        edit_additional
        reset_qc_information
        edit
        change_decision
      ],
      Robot => %i[create edit read delete],
      RobotProperty => %i[create edit read delete],
      Role => %i[create administer edit read delete],
      Sample => %i[edit release accession update_released],
      SampleLogisticsController => %i[read],
      SampleManifest => %i[create new],
      Sequencescape => %i[administer],
      Study => %i[
        administer
        unlink_sample
        link_sample
        edit
        create
        activate
        deactivate
        print_asset_group_labels
        accession
        request_additional_with
        grant_role
        remove_role
      ],
      Submission => %i[create read edit update delete change_priority new order_fields study_assets],
      Supplier => %i[create new],
      TagGroup => %i[create read edit delete],
      TagSet => %i[create read edit delete],
      TagLayoutTemplate => %i[create read edit delete],
      User => %i[administer edit read projects study_reports create delete]
    }
  end

  let(:all_actions) { global_permissions.flat_map { |klass, actions| actions.map { |action| [klass, action] } } }

  let(:basic_permissions) do
    # Permissions granted to all users.
    {
      Batch => %i[edit create_stock_asset sample_prep_worksheet print verify],
      Comment => %i[create delete new],
      Delayed::Job => %i[read],
      Labware => %i[read],
      PlateTemplate => %i[read],
      Project => %i[create read create_submission],
      ReferenceGenome => %i[read],
      Robot => %i[read],
      Sample => %i[edit release accession],
      Study => %i[create read print_asset_group_labels],
      Submission => %i[create read update new order_fields study_assets edit],
      TagGroup => %i[read],
      TagLayoutTemplate => %i[read],
      TagSet => %i[read],
      User => %i[edit read projects study_reports print_swipecard]
    }
  end

  def merge_permissions(*permissions)
    permissions.each_with_object({}) do |permission_to_merge, shared|
      permission_to_merge.each do |klass, actions|
        shared[klass] ||= []
        shared[klass].concat(actions).uniq!
      end
    end
  end

  shared_examples 'it grants only granted_permissions' do
    it 'grants expected permissions', :aggregate_failures do
      all_actions.each do |klass, action|
        next unless granted_permissions.fetch(klass, []).include?(action)

        expect(ability).to be_able_to(action, klass)
      end
    end

    it 'does not grant unexpected permissions', :aggregate_failures do
      all_actions.each do |klass, action|
        next if granted_permissions.fetch(klass, []).include?(action)

        expect(ability).not_to be_able_to(action, klass)
      end
    end
  end

  context 'when there is no user' do
    let(:user) { nil }
    let(:granted_permissions) { {} }

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when there is a basic user' do
    let(:user) { build :user }

    let(:granted_permissions) { basic_permissions }

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "administrator"' do
    let(:user) { build :user, :with_role, role_name: 'administrator' }

    let(:granted_permissions) do
      merge_permissions(
        basic_permissions,
        {
          AssetGroup => %i[create edit read delete new],
          BaitLibrary => %i[create edit read delete],
          BaitLibrary::Supplier => %i[create edit read delete],
          BaitLibraryType => %i[create edit read delete],
          BarcodePrinter => %i[create edit read delete],
          Batch => %i[rollback],
          CustomText => %i[create edit read delete],
          Document => %i[delete],
          FacultySponsor => %i[create edit read delete],
          GelsController => %i[create edit read delete],
          Labware => %i[rename change_purpose edit],
          Order => %i[create new],
          Pipeline => %i[activate deactivate],
          Plate => %i[convert_to_tube],
          PlatePurpose => %i[create new edit read delete],
          PlateTemplate => %i[create edit delete],
          PrimerPanel => %i[create edit read delete],
          Program => %i[create edit read delete],
          Project => %i[administer edit create read delete],
          Purpose => %i[create edit read delete new],
          Receptacle => %i[edit close create read delete],
          ReferenceGenome => %i[create edit delete],
          Request => %i[create_additional copy cancel edit_additional reset_qc_information edit change_decision],
          Robot => %i[create edit delete],
          RobotProperty => %i[create edit read delete],
          Role => %i[create administer edit read delete],
          Sample => %i[update_released],
          SampleLogisticsController => %i[read],
          SampleManifest => %i[create new],
          Sequencescape => %i[administer],
          Study => %i[
            administer
            unlink_sample
            link_sample
            edit
            activate
            deactivate
            accession
            request_additional_with
            grant_role
            remove_role
          ],
          Submission => %i[delete change_priority],
          Supplier => %i[create new],
          TagGroup => %i[create edit delete],
          TagSet => %i[create read edit delete],
          TagLayoutTemplate => %i[create edit delete],
          User => %i[administer create delete]
        }
      )
    end

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "data_access_coordinator"' do
    let(:user) { build :user, :with_role, role_name: 'data_access_coordinator' }

    let(:granted_permissions) { merge_permissions(basic_permissions, { Study => %i[change_ethically_approved] }) }

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "follower"' do
    let(:user) { build :user, :with_role, role_name: 'follower' }

    let(:granted_permissions) { basic_permissions }

    it_behaves_like 'it grants only granted_permissions'

    context 'with specific studies and projects' do
      let(:user) { create :user, :with_role, role_name: 'follower' }
      let(:authorized_project) { create :project, :with_follower, follower: user }
      let(:unauthorized_project) { create :project }
      let(:authorized_study) { create :study, :with_follower, follower: user }
      let(:unauthorized_study) { create :study }

      # Project
      it { is_expected.not_to be_able_to(:administer, authorized_project) }
      it { is_expected.not_to be_able_to(:administer, unauthorized_project) }
      it { is_expected.not_to be_able_to(:edit, authorized_project) }
      it { is_expected.not_to be_able_to(:edit, unauthorized_project) }
      it { is_expected.not_to be_able_to(:create_submission, authorized_project) }
      it { is_expected.not_to be_able_to(:create_submission, unauthorized_project) }
      it { is_expected.to be_able_to(:read, authorized_project) }
      it { is_expected.to be_able_to(:read, unauthorized_project) }
      it { is_expected.not_to be_able_to(:delete, authorized_project) }
      it { is_expected.not_to be_able_to(:delete, unauthorized_project) }

      # Study
      it { is_expected.not_to be_able_to(:administer, authorized_study) }
      it { is_expected.not_to be_able_to(:administer, unauthorized_study) }
      it { is_expected.not_to be_able_to(:unlink_sample, authorized_study) }
      it { is_expected.not_to be_able_to(:unlink_sample, unauthorized_study) }
      it { is_expected.not_to be_able_to(:link_sample, authorized_study) }
      it { is_expected.not_to be_able_to(:link_sample, unauthorized_study) }
      it { is_expected.not_to be_able_to(:edit, authorized_study) }
      it { is_expected.not_to be_able_to(:edit, unauthorized_study) }
      it { is_expected.not_to be_able_to(:activate, authorized_study) }
      it { is_expected.not_to be_able_to(:activate, unauthorized_study) }
      it { is_expected.not_to be_able_to(:deactivate, authorized_study) }
      it { is_expected.not_to be_able_to(:deactivate, unauthorized_study) }
      it { is_expected.not_to be_able_to(:print_asset_group_labels, authorized_study) }
      it { is_expected.not_to be_able_to(:print_asset_group_labels, unauthorized_study) }
      it { is_expected.not_to be_able_to(:accession, authorized_study) }
      it { is_expected.not_to be_able_to(:accession, unauthorized_study) }
      it { is_expected.not_to be_able_to(:request_additional_with, authorized_study) }
      it { is_expected.not_to be_able_to(:request_additional_with, unauthorized_study) }
      it { is_expected.not_to be_able_to(:grant_role, authorized_study) }
      it { is_expected.not_to be_able_to(:grant_role, unauthorized_study) }
      it { is_expected.not_to be_able_to(:remove_role, authorized_study) }
      it { is_expected.not_to be_able_to(:remove_role, unauthorized_study) }
    end
  end

  context 'when the user has the role "lab"' do
    let(:user) { build :user, :with_role, role_name: 'lab' }

    let(:granted_permissions) { basic_permissions }

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "lab_manager"' do
    let(:user) { build :user, :with_role, role_name: 'lab_manager' }

    let(:granted_permissions) do
      merge_permissions(
        basic_permissions,
        {
          Labware => %i[change_purpose edit],
          Pipeline => %i[update_priority],
          PlateTemplate => %i[edit],
          Request => %i[change_priority see_previously_failed],
          Submission => %i[change_priority]
        }
      )
    end

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "manager"' do
    let(:user) { build :user, :with_role, role_name: 'manager' }

    let(:granted_permissions) do
      merge_permissions(
        basic_permissions,
        {
          AssetGroup => %i[create new],
          Labware => %i[edit],
          Order => %i[create new],
          Plate => %i[convert_to_tube],
          Project => %i[edit],
          Receptacle => %i[edit close create read delete],
          Request => %i[create_additional copy cancel change_decision],
          SampleManifest => %i[create new],
          Sequencescape => %i[administer],
          Study => %i[unlink_sample link_sample edit activate deactivate accession request_additional_with],
          Supplier => %i[create new]
        }
      )
    end

    it_behaves_like 'it grants only granted_permissions'

    context 'with specific studies and projects' do
      let(:user) { create :user, :with_role, role_name: 'manager' }
      let(:authorized_project) { create :project, :with_manager, manager: user }
      let(:unauthorized_project) { create :project }
      let(:authorized_study) { create :study, :with_manager, manager: user }
      let(:unauthorized_study) { create :study }

      # Project
      it { is_expected.not_to be_able_to(:administer, authorized_project) }
      it { is_expected.not_to be_able_to(:administer, unauthorized_project) }
      it { is_expected.to be_able_to(:edit, authorized_project) }
      it { is_expected.not_to be_able_to(:edit, unauthorized_project) }
      it { is_expected.to be_able_to(:create_submission, authorized_project) }
      it { is_expected.not_to be_able_to(:create_submission, unauthorized_project) }
      it { is_expected.to be_able_to(:read, authorized_project) }
      it { is_expected.to be_able_to(:read, unauthorized_project) }
      it { is_expected.not_to be_able_to(:delete, authorized_project) }
      it { is_expected.not_to be_able_to(:delete, unauthorized_project) }

      # Study
      it { is_expected.not_to be_able_to(:administer, authorized_study) }
      it { is_expected.not_to be_able_to(:administer, unauthorized_study) }
      it { is_expected.to be_able_to(:unlink_sample, authorized_study) }
      it { is_expected.not_to be_able_to(:unlink_sample, unauthorized_study) }
      it { is_expected.to be_able_to(:link_sample, authorized_study) }
      it { is_expected.not_to be_able_to(:link_sample, unauthorized_study) }
      it { is_expected.to be_able_to(:edit, authorized_study) }
      it { is_expected.to be_able_to(:edit, unauthorized_study) }
      it { is_expected.to be_able_to(:activate, authorized_study) }
      it { is_expected.to be_able_to(:activate, unauthorized_study) }
      it { is_expected.to be_able_to(:deactivate, authorized_study) }
      it { is_expected.to be_able_to(:deactivate, unauthorized_study) }
      it { is_expected.to be_able_to(:print_asset_group_labels, authorized_study) }
      it { is_expected.not_to be_able_to(:print_asset_group_labels, unauthorized_study) }
      it { is_expected.to be_able_to(:accession, authorized_study) }
      it { is_expected.not_to be_able_to(:accession, unauthorized_study) }
      it { is_expected.to be_able_to(:request_additional_with, authorized_study) }
      it { is_expected.not_to be_able_to(:request_additional_with, unauthorized_study) }
      it { is_expected.not_to be_able_to(:grant_role, authorized_study) }
      it { is_expected.not_to be_able_to(:grant_role, unauthorized_study) }
      it { is_expected.not_to be_able_to(:remove_role, authorized_study) }
      it { is_expected.not_to be_able_to(:remove_role, unauthorized_study) }
    end
  end

  context 'when the user has the role "owner"' do
    let(:user) { build :user, :with_role, role_name: 'owner' }

    let(:granted_permissions) { basic_permissions }

    it_behaves_like 'it grants only granted_permissions'

    context 'with specific studies and projects' do
      let(:user) { create :user, :with_role, role_name: 'owner' }
      let(:authorized_project) { create :project, :with_owner, owner: user }
      let(:unauthorized_project) { create :project }
      let(:authorized_sample) { create :sample, :with_owner, owner: user }
      let(:unauthorized_sample) { create :sample }
      let(:authorized_study) { create :study, :with_owner, owner: user }
      let(:unauthorized_study) { create :study }

      # Project
      it { is_expected.not_to be_able_to(:administer, authorized_project) }
      it { is_expected.not_to be_able_to(:administer, unauthorized_project) }
      it { is_expected.not_to be_able_to(:edit, authorized_project) }
      it { is_expected.not_to be_able_to(:edit, unauthorized_project) }
      it { is_expected.to be_able_to(:create_submission, authorized_project) }
      it { is_expected.not_to be_able_to(:create_submission, unauthorized_project) }
      it { is_expected.to be_able_to(:read, authorized_project) }
      it { is_expected.to be_able_to(:read, unauthorized_project) }
      it { is_expected.not_to be_able_to(:delete, authorized_project) }
      it { is_expected.not_to be_able_to(:delete, unauthorized_project) }

      # Sample
      it { is_expected.to be_able_to(:edit, authorized_sample) }
      it { is_expected.not_to be_able_to(:edit, unauthorized_sample) }
      it { is_expected.to be_able_to(:release, authorized_sample) }
      it { is_expected.not_to be_able_to(:release, unauthorized_sample) }
      it { is_expected.to be_able_to(:accession, authorized_sample) }
      it { is_expected.not_to be_able_to(:accession, unauthorized_sample) }
      it { is_expected.not_to be_able_to(:update_released, authorized_sample) }
      it { is_expected.not_to be_able_to(:update_released, unauthorized_sample) }

      # Study
      it { is_expected.not_to be_able_to(:administer, authorized_study) }
      it { is_expected.not_to be_able_to(:administer, unauthorized_study) }
      it { is_expected.not_to be_able_to(:unlink_sample, authorized_study) }
      it { is_expected.not_to be_able_to(:unlink_sample, unauthorized_study) }
      it { is_expected.not_to be_able_to(:link_sample, authorized_study) }
      it { is_expected.not_to be_able_to(:link_sample, unauthorized_study) }
      it { is_expected.not_to be_able_to(:edit, authorized_study) }
      it { is_expected.not_to be_able_to(:edit, unauthorized_study) }
      it { is_expected.not_to be_able_to(:activate, authorized_study) }
      it { is_expected.not_to be_able_to(:activate, unauthorized_study) }
      it { is_expected.not_to be_able_to(:deactivate, authorized_study) }
      it { is_expected.not_to be_able_to(:deactivate, unauthorized_study) }
      it { is_expected.to be_able_to(:print_asset_group_labels, authorized_study) }
      it { is_expected.not_to be_able_to(:print_asset_group_labels, unauthorized_study) }
      it { is_expected.not_to be_able_to(:accession, authorized_study) }
      it { is_expected.not_to be_able_to(:accession, unauthorized_study) }
      it { is_expected.not_to be_able_to(:request_additional_with, authorized_study) }
      it { is_expected.not_to be_able_to(:request_additional_with, unauthorized_study) }
      it { is_expected.not_to be_able_to(:grant_role, authorized_study) }
      it { is_expected.not_to be_able_to(:grant_role, unauthorized_study) }
      it { is_expected.not_to be_able_to(:remove_role, authorized_study) }
      it { is_expected.not_to be_able_to(:remove_role, unauthorized_study) }
    end
  end

  context 'when the user has the role "qa_manager"' do
    let(:user) { build :user, :with_role, role_name: 'qa_manager' }

    let(:granted_permissions) { merge_permissions(basic_permissions, { QcDecision => %i[create new] }) }

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "slf_gel"' do
    let(:user) { build :user, :with_role, role_name: 'slf_gel' }

    let(:granted_permissions) do
      merge_permissions(
        basic_permissions,
        { GelsController => %i[create edit read delete], SampleLogisticsController => %i[read] }
      )
    end

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "slf_manager"' do
    let(:user) { build :user, :with_role, role_name: 'slf_manager' }

    let(:granted_permissions) do
      merge_permissions(
        basic_permissions,
        {
          GelsController => %i[create edit read delete],
          Plate => %i[convert_to_tube],
          PlateTemplate => %i[create edit delete],
          SampleLogisticsController => %i[read],
          SampleManifest => %i[create new],
          Supplier => %i[create new]
        }
      )
    end

    it_behaves_like 'it grants only granted_permissions'
  end
end
