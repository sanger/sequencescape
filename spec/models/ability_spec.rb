# frozen_string_literal: true

require 'cancan/matchers'
# Disable the aggregate example cop as these tests are fast, and it doesn't
# especially help readability
# rubocop:disable RSpec/AggregateExamples
RSpec.describe Ability do
  subject(:ability) { described_class.new(user) }

  let(:user) { nil }

  let(:global_permissions) do
    {
      AssetGroup => %i[create edit read delete new],
      BaitLibrary => %i[create edit read delete],
      BaitLibrary::Supplier => %i[create edit read delete],
      BaitLibraryType => %i[create edit read delete],
      BarcodePrinter => %i[create edit read delete],
      Batch => %i[rollback edit create_stock_asset sample_prep_worksheet print verify],
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
      Request => %i[create_additional copy cancel change_priority see_previously_failed edit_additional reset_qc_information edit change_decision],
      Robot => %i[create edit read delete],
      RobotProperty => %i[create edit read delete],
      Role => %i[create administer edit read delete],
      Sample => %i[edit release accession update_released],
      SampleLogisticsController => %i[read],
      SampleManifest => %i[create new],
      Sequencescape => %i[administer],
      Study => %i[administer unlink_sample link_sample edit create activate deactivate print_asset_group_labels accession request_additional_with grant_role remove_role],
      Submission => %i[create read edit delete change_priority new],
      Supplier => %i[create new],
      TagGroup => %i[create read edit delete],
      TagLayoutTemplate => %i[create read edit delete],
      User => %i[administer edit read projects study_reports create delete]
    }
  end

  let(:all_actions) do
    global_permissions.flat_map do |klass, actions|
      actions.map { |action| [klass, action] }
    end
  end

  shared_examples 'it grants only granted_permissions' do
    it 'grants expected permissions', aggregate_failures: true do
      all_actions.each do |klass, action|
        next unless granted_permissions.fetch(klass, []).include?(action)

        expect(ability).to be_able_to(action, klass)
      end
    end

    it 'does not grant unexpected permissions', aggregate_failures: true do
      all_actions.each do |klass, action|
        next if granted_permissions.fetch(klass, []).include?(action)

        expect(ability).not_to be_able_to(action, klass)
      end
    end
  end

  context 'when there is no user' do
    let(:user) { nil }

    let(:granted_permissions) do
      {

      }
    end

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when there is a basic user' do
    let(:user) { build :user }

    let(:granted_permissions) do
      {
        Batch => %i[edit create_stock_asset sample_prep_worksheet print verify],
        Comment => %i[create delete new],
        Delayed::Job => %i[read],
        Labware => %i[read],
        PlateTemplate => %i[read],
        Project => %i[create_submission],
        ReferenceGenome => %i[read],
        Robot => %i[read],
        Sample => %i[edit release accession],
        Study => %i[print_asset_group_labels],
        Submission => %i[create read new],
        TagGroup => %i[read],
        TagLayoutTemplate => %i[read],
        User => %i[edit read projects study_reports]
      }
    end

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "administrator"' do
    let(:user) { build :user, :with_role, role_name: 'administrator' }

    let(:granted_permissions) do
      {
        AssetGroup => %i[create edit read delete new],
        BaitLibrary => %i[create edit read delete],
        BaitLibrary::Supplier => %i[create edit read delete],
        BaitLibraryType => %i[create edit read delete],
        BarcodePrinter => %i[create edit read delete],
        Batch => %i[rollback edit create_stock_asset sample_prep_worksheet print verify],
        Comment => %i[create delete new],
        CustomText => %i[create edit read delete],
        Delayed::Job => %i[read],
        Document => %i[delete],
        FacultySponsor => %i[create edit read delete],
        GelsController => %i[create edit read delete],
        Labware => %i[rename change_purpose edit read],
        Order => %i[create new],
        Pipeline => %i[activate deactivate],
        Plate => %i[convert_to_tube],
        PlatePurpose => %i[create new edit read delete],
        PlateTemplate => %i[read create edit delete],
        PrimerPanel => %i[create edit read delete],
        Program => %i[create edit read delete],
        Project => %i[administer edit create create_submission read delete],
        Purpose => %i[create edit read delete new],
        Receptacle => %i[edit close create read delete],
        ReferenceGenome => %i[create edit read delete],
        Request => %i[create_additional copy cancel edit_additional reset_qc_information edit change_decision],
        Robot => %i[create edit read delete],
        RobotProperty => %i[create edit read delete],
        Role => %i[create administer edit read delete],
        Sample => %i[edit release accession update_released],
        SampleLogisticsController => %i[read],
        SampleManifest => %i[create new],
        Sequencescape => %i[administer],
        Study => %i[administer unlink_sample link_sample edit activate deactivate print_asset_group_labels accession request_additional_with grant_role remove_role],
        Submission => %i[create read edit delete change_priority new],
        Supplier => %i[create new],
        TagGroup => %i[create read edit delete],
        TagLayoutTemplate => %i[create read edit delete],
        User => %i[administer edit read projects study_reports create delete]
      }
    end

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "data_access_coordinator"' do
    let(:user) { build :user, :with_role, role_name: 'data_access_coordinator' }

    let(:granted_permissions) do
      {
        Batch => %i[edit create_stock_asset sample_prep_worksheet print verify],
        Comment => %i[create delete new],
        Delayed::Job => %i[read],
        Labware => %i[read],
        PlateTemplate => %i[read],
        Project => %i[create_submission],
        ReferenceGenome => %i[read],
        Robot => %i[read],
        Sample => %i[edit release accession],
        Study => %i[print_asset_group_labels],
        Submission => %i[create read new],
        TagGroup => %i[read],
        TagLayoutTemplate => %i[read],
        User => %i[edit read projects study_reports]
      }
    end

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "follower"' do
    let(:user) { build :user, :with_role, role_name: 'follower' }
    let(:authorized_project) { build :project, :with_follower, follower: user }
    let(:unauthorized_project) { build :project }
    let(:authorized_study) { build :study, :with_follower, follower: user }
    let(:unauthorized_study) { build :study }

    let(:granted_permissions) do
      {
        Batch => %i[edit create_stock_asset sample_prep_worksheet print verify],
        Comment => %i[create delete new],
        Delayed::Job => %i[read],
        Labware => %i[read],
        PlateTemplate => %i[read],
        Project => %i[create_submission],
        ReferenceGenome => %i[read],
        Robot => %i[read],
        Sample => %i[edit release accession],
        Study => %i[print_asset_group_labels],
        Submission => %i[create read new],
        TagGroup => %i[read],
        TagLayoutTemplate => %i[read],
        User => %i[edit read projects study_reports]
      }
    end

    it_behaves_like 'it grants only granted_permissions'

    # Project
    it { is_expected.not_to be_able_to(:administer, authorized_project) }
    it { is_expected.not_to be_able_to(:administer, unauthorized_project) }
    it { is_expected.not_to be_able_to(:edit, authorized_project) }
    it { is_expected.not_to be_able_to(:edit, unauthorized_project) }
    it { is_expected.not_to be_able_to(:create, authorized_project) }
    it { is_expected.not_to be_able_to(:create, unauthorized_project) }
    it { is_expected.not_to be_able_to(:create_submission, authorized_project) }
    it { is_expected.not_to be_able_to(:create_submission, unauthorized_project) }
    it { is_expected.not_to be_able_to(:read, authorized_project) }
    it { is_expected.not_to be_able_to(:read, unauthorized_project) }
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
    it { is_expected.not_to be_able_to(:create, authorized_study) }
    it { is_expected.not_to be_able_to(:create, unauthorized_study) }
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

  context 'when the user has the role "lab"' do
    let(:user) { build :user, :with_role, role_name: 'lab' }

    let(:granted_permissions) do
      {
        Batch => %i[edit create_stock_asset sample_prep_worksheet print verify],
        Comment => %i[create delete new],
        Delayed::Job => %i[read],
        Labware => %i[read],
        PlateTemplate => %i[read],
        Project => %i[create_submission],
        ReferenceGenome => %i[read],
        Robot => %i[read],
        Sample => %i[edit release accession],
        Study => %i[print_asset_group_labels],
        Submission => %i[create read new],
        TagGroup => %i[read],
        TagLayoutTemplate => %i[read],
        User => %i[edit read projects study_reports]
      }
    end

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "lab_manager"' do
    let(:user) { build :user, :with_role, role_name: 'lab_manager' }

    let(:granted_permissions) do
      {
        Batch => %i[edit create_stock_asset sample_prep_worksheet print verify],
        Comment => %i[create delete new],
        Delayed::Job => %i[read],
        Labware => %i[change_purpose edit read],
        Pipeline => %i[update_priority],
        PlateTemplate => %i[read edit],
        Project => %i[create_submission],
        ReferenceGenome => %i[read],
        Request => %i[change_priority see_previously_failed],
        Robot => %i[read],
        Sample => %i[edit release accession],
        Study => %i[print_asset_group_labels],
        Submission => %i[create read change_priority new],
        TagGroup => %i[read],
        TagLayoutTemplate => %i[read],
        User => %i[edit read projects study_reports]
      }
    end

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "manager"' do
    let(:user) { build :user, :with_role, role_name: 'manager' }
    let(:authorized_project) { build :project, :with_manager, manager: user }
    let(:unauthorized_project) { build :project }
    let(:authorized_study) { build :study, :with_manager, manager: user }
    let(:unauthorized_study) { build :study }

    let(:granted_permissions) do
      {
        AssetGroup => %i[create new],
        Batch => %i[edit create_stock_asset sample_prep_worksheet print verify],
        Comment => %i[create delete new],
        Delayed::Job => %i[read],
        GelsController => %i[create edit read delete],
        Labware => %i[edit read],
        Order => %i[create new],
        Plate => %i[convert_to_tube],
        PlateTemplate => %i[read create edit delete],
        Project => %i[edit create_submission],
        Receptacle => %i[edit close create read delete],
        ReferenceGenome => %i[read],
        Request => %i[create_additional copy cancel change_decision],
        Robot => %i[read],
        Sample => %i[edit release accession],
        SampleLogisticsController => %i[read],
        SampleManifest => %i[create new],
        Sequencescape => %i[administer],
        Study => %i[unlink_sample link_sample edit activate deactivate print_asset_group_labels accession request_additional_with],
        Submission => %i[create read new],
        Supplier => %i[create new],
        TagGroup => %i[read],
        TagLayoutTemplate => %i[read],
        User => %i[edit read projects study_reports]
      }
    end

    it_behaves_like 'it grants only granted_permissions'

    # Project
    it { is_expected.not_to be_able_to(:administer, authorized_project) }
    it { is_expected.not_to be_able_to(:administer, unauthorized_project) }
    it { is_expected.not_to be_able_to(:edit, authorized_project) }
    it { is_expected.not_to be_able_to(:edit, unauthorized_project) }
    it { is_expected.not_to be_able_to(:create, authorized_project) }
    it { is_expected.not_to be_able_to(:create, unauthorized_project) }
    it { is_expected.to be_able_to(:create_submission, authorized_project) }
    it { is_expected.to be_able_to(:create_submission, unauthorized_project) }
    it { is_expected.not_to be_able_to(:read, authorized_project) }
    it { is_expected.not_to be_able_to(:read, unauthorized_project) }
    it { is_expected.not_to be_able_to(:delete, authorized_project) }
    it { is_expected.not_to be_able_to(:delete, unauthorized_project) }
    # Study
    it { is_expected.not_to be_able_to(:administer, authorized_study) }
    it { is_expected.not_to be_able_to(:administer, unauthorized_study) }
    it { is_expected.not_to be_able_to(:unlink_sample, authorized_study) }
    it { is_expected.not_to be_able_to(:unlink_sample, unauthorized_study) }
    it { is_expected.not_to be_able_to(:link_sample, authorized_study) }
    it { is_expected.not_to be_able_to(:link_sample, unauthorized_study) }
    it { is_expected.to be_able_to(:edit, authorized_study) }
    it { is_expected.to be_able_to(:edit, unauthorized_study) }
    it { is_expected.not_to be_able_to(:create, authorized_study) }
    it { is_expected.not_to be_able_to(:create, unauthorized_study) }
    it { is_expected.to be_able_to(:activate, authorized_study) }
    it { is_expected.to be_able_to(:activate, unauthorized_study) }
    it { is_expected.to be_able_to(:deactivate, authorized_study) }
    it { is_expected.to be_able_to(:deactivate, unauthorized_study) }
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

  context 'when the user has the role "owner"' do
    let(:user) { build :user, :with_role, role_name: 'owner' }
    let(:authorized_project) { build :project, :with_owner, owner: user }
    let(:unauthorized_project) { build :project }
    let(:authorized_sample) { build :sample, :with_owner, owner: user }
    let(:unauthorized_sample) { build :sample }
    let(:authorized_study) { build :study, :with_owner, owner: user }
    let(:unauthorized_study) { build :study }

    let(:granted_permissions) do
      {
        Batch => %i[edit create_stock_asset sample_prep_worksheet print verify],
        Comment => %i[create delete new],
        Delayed::Job => %i[read],
        Labware => %i[read],
        PlateTemplate => %i[read],
        Project => %i[create_submission],
        ReferenceGenome => %i[read],
        Robot => %i[read],
        Sample => %i[edit release accession],
        Study => %i[print_asset_group_labels],
        Submission => %i[create read new],
        TagGroup => %i[read],
        TagLayoutTemplate => %i[read],
        User => %i[edit read projects study_reports]
      }
    end

    it_behaves_like 'it grants only granted_permissions'

    # Project
    it { is_expected.not_to be_able_to(:administer, authorized_project) }
    it { is_expected.not_to be_able_to(:administer, unauthorized_project) }
    it { is_expected.not_to be_able_to(:edit, authorized_project) }
    it { is_expected.not_to be_able_to(:edit, unauthorized_project) }
    it { is_expected.not_to be_able_to(:create, authorized_project) }
    it { is_expected.not_to be_able_to(:create, unauthorized_project) }
    it { is_expected.not_to be_able_to(:create_submission, authorized_project) }
    it { is_expected.not_to be_able_to(:create_submission, unauthorized_project) }
    it { is_expected.not_to be_able_to(:read, authorized_project) }
    it { is_expected.not_to be_able_to(:read, unauthorized_project) }
    it { is_expected.not_to be_able_to(:delete, authorized_project) }
    it { is_expected.not_to be_able_to(:delete, unauthorized_project) }
    # Sample
    it { is_expected.not_to be_able_to(:edit, authorized_sample) }
    it { is_expected.not_to be_able_to(:edit, unauthorized_sample) }
    it { is_expected.not_to be_able_to(:release, authorized_sample) }
    it { is_expected.not_to be_able_to(:release, unauthorized_sample) }
    it { is_expected.not_to be_able_to(:accession, authorized_sample) }
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
    it { is_expected.not_to be_able_to(:create, authorized_study) }
    it { is_expected.not_to be_able_to(:create, unauthorized_study) }
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

  context 'when the user has the role "qa_manager"' do
    let(:user) { build :user, :with_role, role_name: 'qa_manager' }

    let(:granted_permissions) do
      {
        Batch => %i[edit create_stock_asset sample_prep_worksheet print verify],
        Comment => %i[create delete new],
        Delayed::Job => %i[read],
        Labware => %i[read],
        PlateTemplate => %i[read],
        Project => %i[create_submission],
        QcDecision => %i[create new],
        ReferenceGenome => %i[read],
        Robot => %i[read],
        Sample => %i[edit release accession],
        Study => %i[print_asset_group_labels],
        Submission => %i[create read new],
        TagGroup => %i[read],
        TagLayoutTemplate => %i[read],
        User => %i[edit read projects study_reports]
      }
    end

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "slf_gel"' do
    let(:user) { build :user, :with_role, role_name: 'slf_gel' }

    let(:granted_permissions) do
      {
        Batch => %i[edit create_stock_asset sample_prep_worksheet print verify],
        Comment => %i[create delete new],
        Delayed::Job => %i[read],
        GelsController => %i[create edit read delete],
        Labware => %i[read],
        PlateTemplate => %i[read],
        Project => %i[create_submission],
        ReferenceGenome => %i[read],
        Robot => %i[read],
        Sample => %i[edit release accession],
        SampleLogisticsController => %i[read],
        Study => %i[print_asset_group_labels],
        Submission => %i[create read new],
        TagGroup => %i[read],
        TagLayoutTemplate => %i[read],
        User => %i[edit read projects study_reports]
      }
    end

    it_behaves_like 'it grants only granted_permissions'
  end

  context 'when the user has the role "slf_manager"' do
    let(:user) { build :user, :with_role, role_name: 'slf_manager' }

    let(:granted_permissions) do
      {
        Batch => %i[edit create_stock_asset sample_prep_worksheet print verify],
        Comment => %i[create delete new],
        Delayed::Job => %i[read],
        GelsController => %i[create edit read delete],
        Labware => %i[read],
        Plate => %i[convert_to_tube],
        PlateTemplate => %i[read create edit delete],
        Project => %i[create_submission],
        ReferenceGenome => %i[read],
        Robot => %i[read],
        Sample => %i[edit release accession],
        SampleLogisticsController => %i[read],
        SampleManifest => %i[create new],
        Study => %i[print_asset_group_labels],
        Submission => %i[create read new],
        Supplier => %i[create new],
        TagGroup => %i[read],
        TagLayoutTemplate => %i[read],
        User => %i[edit read projects study_reports]
      }
    end

    it_behaves_like 'it grants only granted_permissions'
  end
end
# rubocop:enable RSpec/AggregateExamples
