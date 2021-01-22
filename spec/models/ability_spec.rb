# frozen_string_literal: true

require 'cancan/matchers'
# rubocop:disable RSpec/AggregateExamples
RSpec.describe Ability do
  subject(:ability) { described_class.new(user) }

  let(:user) { nil }

  context 'when there is no user' do
    let(:user) { nil }

    # AssetGroup
    it { is_expected.not_to be_able_to(:create, AssetGroup) }
    it { is_expected.not_to be_able_to(:edit, AssetGroup) }
    it { is_expected.not_to be_able_to(:read, AssetGroup) }
    it { is_expected.not_to be_able_to(:delete, AssetGroup) }
    it { is_expected.not_to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.not_to be_able_to(:create, BaitLibrary) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.not_to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.not_to be_able_to(:create, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:read, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.not_to be_able_to(:create, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:read, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.not_to be_able_to(:rollback, Batch) }
    it { is_expected.not_to be_able_to(:edit, Batch) }
    it { is_expected.not_to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.not_to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.not_to be_able_to(:print, Batch) }
    it { is_expected.not_to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.not_to be_able_to(:create, Comment) }
    it { is_expected.not_to be_able_to(:delete, Comment) }
    it { is_expected.not_to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.not_to be_able_to(:create, CustomText) }
    it { is_expected.not_to be_able_to(:edit, CustomText) }
    it { is_expected.not_to be_able_to(:read, CustomText) }
    it { is_expected.not_to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.not_to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.not_to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.not_to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.not_to be_able_to(:create, FacultySponsor) }
    it { is_expected.not_to be_able_to(:edit, FacultySponsor) }
    it { is_expected.not_to be_able_to(:read, FacultySponsor) }
    it { is_expected.not_to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.not_to be_able_to(:create, GelsController) }
    it { is_expected.not_to be_able_to(:edit, GelsController) }
    it { is_expected.not_to be_able_to(:read, GelsController) }
    it { is_expected.not_to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.not_to be_able_to(:rename, Labware) }
    it { is_expected.not_to be_able_to(:change_purpose, Labware) }
    it { is_expected.not_to be_able_to(:edit, Labware) }
    it { is_expected.not_to be_able_to(:create, Labware) }
    it { is_expected.not_to be_able_to(:read, Labware) }
    it { is_expected.not_to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.not_to be_able_to(:create, Order) }
    it { is_expected.not_to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.not_to be_able_to(:activate, Pipeline) }
    it { is_expected.not_to be_able_to(:deactivate, Pipeline) }
    it { is_expected.not_to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.not_to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.not_to be_able_to(:create, PlatePurpose) }
    it { is_expected.not_to be_able_to(:new, PlatePurpose) }
    it { is_expected.not_to be_able_to(:edit, PlatePurpose) }
    it { is_expected.not_to be_able_to(:read, PlatePurpose) }
    it { is_expected.not_to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.not_to be_able_to(:read, PlateTemplate) }
    it { is_expected.not_to be_able_to(:create, PlateTemplate) }
    it { is_expected.not_to be_able_to(:edit, PlateTemplate) }
    it { is_expected.not_to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.not_to be_able_to(:create, PrimerPanel) }
    it { is_expected.not_to be_able_to(:edit, PrimerPanel) }
    it { is_expected.not_to be_able_to(:read, PrimerPanel) }
    it { is_expected.not_to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.not_to be_able_to(:create, Program) }
    it { is_expected.not_to be_able_to(:edit, Program) }
    it { is_expected.not_to be_able_to(:read, Program) }
    it { is_expected.not_to be_able_to(:delete, Program) }

    # Project
    it { is_expected.not_to be_able_to(:administer, Project) }
    it { is_expected.not_to be_able_to(:edit, Project) }
    it { is_expected.not_to be_able_to(:create, Project) }
    it { is_expected.not_to be_able_to(:create_submission, Project) }
    it { is_expected.not_to be_able_to(:read, Project) }
    it { is_expected.not_to be_able_to(:delete, Project) }

    # Purpose
    it { is_expected.not_to be_able_to(:create, Purpose) }
    it { is_expected.not_to be_able_to(:edit, Purpose) }
    it { is_expected.not_to be_able_to(:read, Purpose) }
    it { is_expected.not_to be_able_to(:delete, Purpose) }
    it { is_expected.not_to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.not_to be_able_to(:create, QcDecision) }
    it { is_expected.not_to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.not_to be_able_to(:edit, Receptacle) }
    it { is_expected.not_to be_able_to(:close, Receptacle) }
    it { is_expected.not_to be_able_to(:create, Receptacle) }
    it { is_expected.not_to be_able_to(:read, Receptacle) }
    it { is_expected.not_to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.not_to be_able_to(:create, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:read, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.not_to be_able_to(:create_additional, Request) }
    it { is_expected.not_to be_able_to(:copy, Request) }
    it { is_expected.not_to be_able_to(:cancel, Request) }
    it { is_expected.not_to be_able_to(:change_priority, Request) }
    it { is_expected.not_to be_able_to(:see_previously_failed, Request) }
    it { is_expected.not_to be_able_to(:edit_additional, Request) }
    it { is_expected.not_to be_able_to(:reset_qc_information, Request) }
    it { is_expected.not_to be_able_to(:edit, Request) }
    it { is_expected.not_to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.not_to be_able_to(:create, Robot) }
    it { is_expected.not_to be_able_to(:edit, Robot) }
    it { is_expected.not_to be_able_to(:read, Robot) }
    it { is_expected.not_to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.not_to be_able_to(:create, RobotProperty) }
    it { is_expected.not_to be_able_to(:edit, RobotProperty) }
    it { is_expected.not_to be_able_to(:read, RobotProperty) }
    it { is_expected.not_to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.not_to be_able_to(:create, Role) }
    it { is_expected.not_to be_able_to(:administer, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.not_to be_able_to(:edit, Sample) }
    it { is_expected.not_to be_able_to(:release, Sample) }
    it { is_expected.not_to be_able_to(:accession, Sample) }
    it { is_expected.not_to be_able_to(:update_released, Sample) }

    # SampleLogisticsController
    it { is_expected.not_to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.not_to be_able_to(:create, SampleManifest) }
    it { is_expected.not_to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.not_to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.not_to be_able_to(:administer, Study) }
    it { is_expected.not_to be_able_to(:unlink_sample, Study) }
    it { is_expected.not_to be_able_to(:link_sample, Study) }
    it { is_expected.not_to be_able_to(:edit, Study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.not_to be_able_to(:activate, Study) }
    it { is_expected.not_to be_able_to(:deactivate, Study) }
    it { is_expected.not_to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.not_to be_able_to(:accession, Study) }
    it { is_expected.not_to be_able_to(:request_additional_with, Study) }
    it { is_expected.not_to be_able_to(:grant_role, Study) }
    it { is_expected.not_to be_able_to(:remove_role, Study) }

    # Submission
    it { is_expected.not_to be_able_to(:create, Submission) }
    it { is_expected.not_to be_able_to(:read, Submission) }
    it { is_expected.not_to be_able_to(:edit, Submission) }
    it { is_expected.not_to be_able_to(:delete, Submission) }
    it { is_expected.not_to be_able_to(:change_priority, Submission) }
    it { is_expected.not_to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.not_to be_able_to(:create, Supplier) }
    it { is_expected.not_to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.not_to be_able_to(:create, TagGroup) }
    it { is_expected.not_to be_able_to(:read, TagGroup) }
    it { is_expected.not_to be_able_to(:edit, TagGroup) }
    it { is_expected.not_to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.not_to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.not_to be_able_to(:administer, User) }
    it { is_expected.not_to be_able_to(:edit, User) }
    it { is_expected.not_to be_able_to(:read, User) }
    it { is_expected.not_to be_able_to(:projects, User) }
    it { is_expected.not_to be_able_to(:study_reports, User) }
    it { is_expected.not_to be_able_to(:create, User) }
    it { is_expected.not_to be_able_to(:delete, User) }
  end

  context 'when there is a basic user' do
    let(:user) { build :user }

    # AssetGroup
    it { is_expected.not_to be_able_to(:create, AssetGroup) }
    it { is_expected.not_to be_able_to(:edit, AssetGroup) }
    it { is_expected.not_to be_able_to(:read, AssetGroup) }
    it { is_expected.not_to be_able_to(:delete, AssetGroup) }
    it { is_expected.not_to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.not_to be_able_to(:create, BaitLibrary) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.not_to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.not_to be_able_to(:create, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:read, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.not_to be_able_to(:create, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:read, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.not_to be_able_to(:rollback, Batch) }
    it { is_expected.to be_able_to(:edit, Batch) }
    it { is_expected.to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.to be_able_to(:print, Batch) }
    it { is_expected.to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.to be_able_to(:create, Comment) }
    it { is_expected.to be_able_to(:delete, Comment) }
    it { is_expected.to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.not_to be_able_to(:create, CustomText) }
    it { is_expected.not_to be_able_to(:edit, CustomText) }
    it { is_expected.not_to be_able_to(:read, CustomText) }
    it { is_expected.not_to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.not_to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.not_to be_able_to(:create, FacultySponsor) }
    it { is_expected.not_to be_able_to(:edit, FacultySponsor) }
    it { is_expected.not_to be_able_to(:read, FacultySponsor) }
    it { is_expected.not_to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.not_to be_able_to(:create, GelsController) }
    it { is_expected.not_to be_able_to(:edit, GelsController) }
    it { is_expected.not_to be_able_to(:read, GelsController) }
    it { is_expected.not_to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.not_to be_able_to(:rename, Labware) }
    it { is_expected.not_to be_able_to(:change_purpose, Labware) }
    it { is_expected.not_to be_able_to(:edit, Labware) }
    it { is_expected.not_to be_able_to(:create, Labware) }
    it { is_expected.not_to be_able_to(:read, Labware) }
    it { is_expected.not_to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.not_to be_able_to(:create, Order) }
    it { is_expected.not_to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.not_to be_able_to(:activate, Pipeline) }
    it { is_expected.not_to be_able_to(:deactivate, Pipeline) }
    it { is_expected.not_to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.not_to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.not_to be_able_to(:create, PlatePurpose) }
    it { is_expected.not_to be_able_to(:new, PlatePurpose) }
    it { is_expected.not_to be_able_to(:edit, PlatePurpose) }
    it { is_expected.not_to be_able_to(:read, PlatePurpose) }
    it { is_expected.not_to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.not_to be_able_to(:read, PlateTemplate) }
    it { is_expected.not_to be_able_to(:create, PlateTemplate) }
    it { is_expected.not_to be_able_to(:edit, PlateTemplate) }
    it { is_expected.not_to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.not_to be_able_to(:create, PrimerPanel) }
    it { is_expected.not_to be_able_to(:edit, PrimerPanel) }
    it { is_expected.not_to be_able_to(:read, PrimerPanel) }
    it { is_expected.not_to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.not_to be_able_to(:create, Program) }
    it { is_expected.not_to be_able_to(:edit, Program) }
    it { is_expected.not_to be_able_to(:read, Program) }
    it { is_expected.not_to be_able_to(:delete, Program) }

    # Project
    it { is_expected.not_to be_able_to(:administer, Project) }
    it { is_expected.not_to be_able_to(:edit, Project) }
    it { is_expected.not_to be_able_to(:create, Project) }
    it { is_expected.to be_able_to(:create_submission, Project) }
    it { is_expected.not_to be_able_to(:read, Project) }
    it { is_expected.not_to be_able_to(:delete, Project) }

    # Purpose
    it { is_expected.not_to be_able_to(:create, Purpose) }
    it { is_expected.not_to be_able_to(:edit, Purpose) }
    it { is_expected.not_to be_able_to(:read, Purpose) }
    it { is_expected.not_to be_able_to(:delete, Purpose) }
    it { is_expected.not_to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.not_to be_able_to(:create, QcDecision) }
    it { is_expected.not_to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.not_to be_able_to(:edit, Receptacle) }
    it { is_expected.not_to be_able_to(:close, Receptacle) }
    it { is_expected.not_to be_able_to(:create, Receptacle) }
    it { is_expected.not_to be_able_to(:read, Receptacle) }
    it { is_expected.not_to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.not_to be_able_to(:create, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.to be_able_to(:read, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.not_to be_able_to(:create_additional, Request) }
    it { is_expected.not_to be_able_to(:copy, Request) }
    it { is_expected.not_to be_able_to(:cancel, Request) }
    it { is_expected.not_to be_able_to(:change_priority, Request) }
    it { is_expected.not_to be_able_to(:see_previously_failed, Request) }
    it { is_expected.not_to be_able_to(:edit_additional, Request) }
    it { is_expected.not_to be_able_to(:reset_qc_information, Request) }
    it { is_expected.not_to be_able_to(:edit, Request) }
    it { is_expected.not_to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.not_to be_able_to(:create, Robot) }
    it { is_expected.not_to be_able_to(:edit, Robot) }
    it { is_expected.to be_able_to(:read, Robot) }
    it { is_expected.not_to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.not_to be_able_to(:create, RobotProperty) }
    it { is_expected.not_to be_able_to(:edit, RobotProperty) }
    it { is_expected.not_to be_able_to(:read, RobotProperty) }
    it { is_expected.not_to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.not_to be_able_to(:create, Role) }
    it { is_expected.not_to be_able_to(:administer, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.to be_able_to(:edit, Sample) }
    it { is_expected.to be_able_to(:release, Sample) }
    it { is_expected.to be_able_to(:accession, Sample) }
    it { is_expected.not_to be_able_to(:update_released, Sample) }

    # SampleLogisticsController
    it { is_expected.not_to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.not_to be_able_to(:create, SampleManifest) }
    it { is_expected.not_to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.not_to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.not_to be_able_to(:administer, Study) }
    it { is_expected.not_to be_able_to(:unlink_sample, Study) }
    it { is_expected.not_to be_able_to(:link_sample, Study) }
    it { is_expected.not_to be_able_to(:edit, Study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.not_to be_able_to(:activate, Study) }
    it { is_expected.not_to be_able_to(:deactivate, Study) }
    it { is_expected.to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.not_to be_able_to(:accession, Study) }
    it { is_expected.not_to be_able_to(:request_additional_with, Study) }
    it { is_expected.not_to be_able_to(:grant_role, Study) }
    it { is_expected.not_to be_able_to(:remove_role, Study) }

    # Submission
    it { is_expected.to be_able_to(:create, Submission) }
    it { is_expected.to be_able_to(:read, Submission) }
    it { is_expected.not_to be_able_to(:edit, Submission) }
    it { is_expected.not_to be_able_to(:delete, Submission) }
    it { is_expected.not_to be_able_to(:change_priority, Submission) }
    it { is_expected.to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.not_to be_able_to(:create, Supplier) }
    it { is_expected.not_to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.not_to be_able_to(:create, TagGroup) }
    it { is_expected.to be_able_to(:read, TagGroup) }
    it { is_expected.not_to be_able_to(:edit, TagGroup) }
    it { is_expected.not_to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.not_to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.not_to be_able_to(:administer, User) }
    it { is_expected.to be_able_to(:edit, User) }
    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:projects, User) }
    it { is_expected.to be_able_to(:study_reports, User) }
    it { is_expected.not_to be_able_to(:create, User) }
    it { is_expected.not_to be_able_to(:delete, User) }
  end

  context 'when the user has the role "administrator"' do
    let(:user) { build :user, :with_role, role_name: 'administrator' }

    # AssetGroup
    it { is_expected.to be_able_to(:create, AssetGroup) }
    it { is_expected.to be_able_to(:edit, AssetGroup) }
    it { is_expected.to be_able_to(:read, AssetGroup) }
    it { is_expected.to be_able_to(:delete, AssetGroup) }
    it { is_expected.to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.to be_able_to(:create, BaitLibrary) }
    it { is_expected.to be_able_to(:edit, BaitLibrary) }
    it { is_expected.to be_able_to(:read, BaitLibrary) }
    it { is_expected.to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.to be_able_to(:create, BaitLibraryType) }
    it { is_expected.to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.to be_able_to(:read, BaitLibraryType) }
    it { is_expected.to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.to be_able_to(:create, BarcodePrinter) }
    it { is_expected.to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.to be_able_to(:read, BarcodePrinter) }
    it { is_expected.to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.to be_able_to(:rollback, Batch) }
    it { is_expected.to be_able_to(:edit, Batch) }
    it { is_expected.to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.to be_able_to(:print, Batch) }
    it { is_expected.to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.to be_able_to(:create, Comment) }
    it { is_expected.to be_able_to(:delete, Comment) }
    it { is_expected.to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.to be_able_to(:create, CustomText) }
    it { is_expected.to be_able_to(:edit, CustomText) }
    it { is_expected.to be_able_to(:read, CustomText) }
    it { is_expected.to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.to be_able_to(:create, FacultySponsor) }
    it { is_expected.to be_able_to(:edit, FacultySponsor) }
    it { is_expected.to be_able_to(:read, FacultySponsor) }
    it { is_expected.to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.to be_able_to(:create, GelsController) }
    it { is_expected.to be_able_to(:edit, GelsController) }
    it { is_expected.to be_able_to(:read, GelsController) }
    it { is_expected.to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.to be_able_to(:rename, Labware) }
    it { is_expected.to be_able_to(:change_purpose, Labware) }
    it { is_expected.to be_able_to(:edit, Labware) }
    it { is_expected.to be_able_to(:create, Labware) }
    it { is_expected.to be_able_to(:read, Labware) }
    it { is_expected.to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.to be_able_to(:create, Order) }
    it { is_expected.to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.to be_able_to(:activate, Pipeline) }
    it { is_expected.to be_able_to(:deactivate, Pipeline) }
    it { is_expected.not_to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.to be_able_to(:create, PlatePurpose) }
    it { is_expected.to be_able_to(:new, PlatePurpose) }
    it { is_expected.to be_able_to(:edit, PlatePurpose) }
    it { is_expected.to be_able_to(:read, PlatePurpose) }
    it { is_expected.to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.to be_able_to(:read, PlateTemplate) }
    it { is_expected.to be_able_to(:create, PlateTemplate) }
    it { is_expected.to be_able_to(:edit, PlateTemplate) }
    it { is_expected.to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.to be_able_to(:create, PrimerPanel) }
    it { is_expected.to be_able_to(:edit, PrimerPanel) }
    it { is_expected.to be_able_to(:read, PrimerPanel) }
    it { is_expected.to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.to be_able_to(:create, Program) }
    it { is_expected.to be_able_to(:edit, Program) }
    it { is_expected.to be_able_to(:read, Program) }
    it { is_expected.to be_able_to(:delete, Program) }

    # Project
    it { is_expected.to be_able_to(:administer, Project) }
    it { is_expected.to be_able_to(:edit, Project) }
    it { is_expected.to be_able_to(:create, Project) }
    it { is_expected.to be_able_to(:create_submission, Project) }
    it { is_expected.to be_able_to(:read, Project) }
    it { is_expected.to be_able_to(:delete, Project) }

    # Purpose
    it { is_expected.to be_able_to(:create, Purpose) }
    it { is_expected.to be_able_to(:edit, Purpose) }
    it { is_expected.to be_able_to(:read, Purpose) }
    it { is_expected.to be_able_to(:delete, Purpose) }
    it { is_expected.to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.not_to be_able_to(:create, QcDecision) }
    it { is_expected.not_to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.to be_able_to(:edit, Receptacle) }
    it { is_expected.to be_able_to(:close, Receptacle) }
    it { is_expected.to be_able_to(:create, Receptacle) }
    it { is_expected.to be_able_to(:read, Receptacle) }
    it { is_expected.to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.to be_able_to(:create, ReferenceGenome) }
    it { is_expected.to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.to be_able_to(:read, ReferenceGenome) }
    it { is_expected.to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.to be_able_to(:create_additional, Request) }
    it { is_expected.to be_able_to(:copy, Request) }
    it { is_expected.to be_able_to(:cancel, Request) }
    it { is_expected.not_to be_able_to(:change_priority, Request) }
    it { is_expected.not_to be_able_to(:see_previously_failed, Request) }
    it { is_expected.to be_able_to(:edit_additional, Request) }
    it { is_expected.to be_able_to(:reset_qc_information, Request) }
    it { is_expected.to be_able_to(:edit, Request) }
    it { is_expected.to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.to be_able_to(:create, Robot) }
    it { is_expected.to be_able_to(:edit, Robot) }
    it { is_expected.to be_able_to(:read, Robot) }
    it { is_expected.to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.to be_able_to(:create, RobotProperty) }
    it { is_expected.to be_able_to(:edit, RobotProperty) }
    it { is_expected.to be_able_to(:read, RobotProperty) }
    it { is_expected.to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.to be_able_to(:create, Role) }
    it { is_expected.to be_able_to(:administer, Role) }
    it { is_expected.to be_able_to(:edit, Role) }
    it { is_expected.to be_able_to(:read, Role) }
    it { is_expected.to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.to be_able_to(:edit, Sample) }
    it { is_expected.to be_able_to(:release, Sample) }
    it { is_expected.to be_able_to(:accession, Sample) }
    it { is_expected.to be_able_to(:update_released, Sample) }

    # SampleLogisticsController
    it { is_expected.to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.to be_able_to(:create, SampleManifest) }
    it { is_expected.to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.to be_able_to(:administer, Study) }
    it { is_expected.to be_able_to(:unlink_sample, Study) }
    it { is_expected.to be_able_to(:link_sample, Study) }
    it { is_expected.to be_able_to(:edit, Study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.to be_able_to(:activate, Study) }
    it { is_expected.to be_able_to(:deactivate, Study) }
    it { is_expected.to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.to be_able_to(:accession, Study) }
    it { is_expected.to be_able_to(:request_additional_with, Study) }
    it { is_expected.to be_able_to(:grant_role, Study) }
    it { is_expected.to be_able_to(:remove_role, Study) }

    # Submission
    it { is_expected.to be_able_to(:create, Submission) }
    it { is_expected.to be_able_to(:read, Submission) }
    it { is_expected.to be_able_to(:edit, Submission) }
    it { is_expected.to be_able_to(:delete, Submission) }
    it { is_expected.to be_able_to(:change_priority, Submission) }
    it { is_expected.to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.to be_able_to(:create, Supplier) }
    it { is_expected.to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.to be_able_to(:create, TagGroup) }
    it { is_expected.to be_able_to(:read, TagGroup) }
    it { is_expected.to be_able_to(:edit, TagGroup) }
    it { is_expected.to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.to be_able_to(:administer, User) }
    it { is_expected.to be_able_to(:edit, User) }
    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:projects, User) }
    it { is_expected.to be_able_to(:study_reports, User) }
    it { is_expected.to be_able_to(:create, User) }
    it { is_expected.to be_able_to(:delete, User) }
  end

  context 'when the user has the role "data_access_coordinator"' do
    let(:user) { build :user, :with_role, role_name: 'data_access_coordinator' }

    # AssetGroup
    it { is_expected.not_to be_able_to(:create, AssetGroup) }
    it { is_expected.not_to be_able_to(:edit, AssetGroup) }
    it { is_expected.not_to be_able_to(:read, AssetGroup) }
    it { is_expected.not_to be_able_to(:delete, AssetGroup) }
    it { is_expected.not_to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.not_to be_able_to(:create, BaitLibrary) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.not_to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.not_to be_able_to(:create, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:read, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.not_to be_able_to(:create, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:read, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.not_to be_able_to(:rollback, Batch) }
    it { is_expected.to be_able_to(:edit, Batch) }
    it { is_expected.to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.to be_able_to(:print, Batch) }
    it { is_expected.to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.to be_able_to(:create, Comment) }
    it { is_expected.to be_able_to(:delete, Comment) }
    it { is_expected.to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.not_to be_able_to(:create, CustomText) }
    it { is_expected.not_to be_able_to(:edit, CustomText) }
    it { is_expected.not_to be_able_to(:read, CustomText) }
    it { is_expected.not_to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.not_to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.not_to be_able_to(:create, FacultySponsor) }
    it { is_expected.not_to be_able_to(:edit, FacultySponsor) }
    it { is_expected.not_to be_able_to(:read, FacultySponsor) }
    it { is_expected.not_to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.not_to be_able_to(:create, GelsController) }
    it { is_expected.not_to be_able_to(:edit, GelsController) }
    it { is_expected.not_to be_able_to(:read, GelsController) }
    it { is_expected.not_to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.not_to be_able_to(:rename, Labware) }
    it { is_expected.not_to be_able_to(:change_purpose, Labware) }
    it { is_expected.not_to be_able_to(:edit, Labware) }
    it { is_expected.not_to be_able_to(:create, Labware) }
    it { is_expected.not_to be_able_to(:read, Labware) }
    it { is_expected.not_to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.not_to be_able_to(:create, Order) }
    it { is_expected.not_to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.not_to be_able_to(:activate, Pipeline) }
    it { is_expected.not_to be_able_to(:deactivate, Pipeline) }
    it { is_expected.not_to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.not_to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.not_to be_able_to(:create, PlatePurpose) }
    it { is_expected.not_to be_able_to(:new, PlatePurpose) }
    it { is_expected.not_to be_able_to(:edit, PlatePurpose) }
    it { is_expected.not_to be_able_to(:read, PlatePurpose) }
    it { is_expected.not_to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.not_to be_able_to(:read, PlateTemplate) }
    it { is_expected.not_to be_able_to(:create, PlateTemplate) }
    it { is_expected.not_to be_able_to(:edit, PlateTemplate) }
    it { is_expected.not_to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.not_to be_able_to(:create, PrimerPanel) }
    it { is_expected.not_to be_able_to(:edit, PrimerPanel) }
    it { is_expected.not_to be_able_to(:read, PrimerPanel) }
    it { is_expected.not_to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.not_to be_able_to(:create, Program) }
    it { is_expected.not_to be_able_to(:edit, Program) }
    it { is_expected.not_to be_able_to(:read, Program) }
    it { is_expected.not_to be_able_to(:delete, Program) }

    # Project
    it { is_expected.not_to be_able_to(:administer, Project) }
    it { is_expected.not_to be_able_to(:edit, Project) }
    it { is_expected.not_to be_able_to(:create, Project) }
    it { is_expected.to be_able_to(:create_submission, Project) }
    it { is_expected.not_to be_able_to(:read, Project) }
    it { is_expected.not_to be_able_to(:delete, Project) }

    # Purpose
    it { is_expected.not_to be_able_to(:create, Purpose) }
    it { is_expected.not_to be_able_to(:edit, Purpose) }
    it { is_expected.not_to be_able_to(:read, Purpose) }
    it { is_expected.not_to be_able_to(:delete, Purpose) }
    it { is_expected.not_to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.not_to be_able_to(:create, QcDecision) }
    it { is_expected.not_to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.not_to be_able_to(:edit, Receptacle) }
    it { is_expected.not_to be_able_to(:close, Receptacle) }
    it { is_expected.not_to be_able_to(:create, Receptacle) }
    it { is_expected.not_to be_able_to(:read, Receptacle) }
    it { is_expected.not_to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.not_to be_able_to(:create, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.to be_able_to(:read, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.not_to be_able_to(:create_additional, Request) }
    it { is_expected.not_to be_able_to(:copy, Request) }
    it { is_expected.not_to be_able_to(:cancel, Request) }
    it { is_expected.not_to be_able_to(:change_priority, Request) }
    it { is_expected.not_to be_able_to(:see_previously_failed, Request) }
    it { is_expected.not_to be_able_to(:edit_additional, Request) }
    it { is_expected.not_to be_able_to(:reset_qc_information, Request) }
    it { is_expected.not_to be_able_to(:edit, Request) }
    it { is_expected.not_to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.not_to be_able_to(:create, Robot) }
    it { is_expected.not_to be_able_to(:edit, Robot) }
    it { is_expected.to be_able_to(:read, Robot) }
    it { is_expected.not_to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.not_to be_able_to(:create, RobotProperty) }
    it { is_expected.not_to be_able_to(:edit, RobotProperty) }
    it { is_expected.not_to be_able_to(:read, RobotProperty) }
    it { is_expected.not_to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.not_to be_able_to(:create, Role) }
    it { is_expected.not_to be_able_to(:administer, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.to be_able_to(:edit, Sample) }
    it { is_expected.to be_able_to(:release, Sample) }
    it { is_expected.to be_able_to(:accession, Sample) }
    it { is_expected.not_to be_able_to(:update_released, Sample) }

    # SampleLogisticsController
    it { is_expected.not_to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.not_to be_able_to(:create, SampleManifest) }
    it { is_expected.not_to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.not_to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.not_to be_able_to(:administer, Study) }
    it { is_expected.not_to be_able_to(:unlink_sample, Study) }
    it { is_expected.not_to be_able_to(:link_sample, Study) }
    it { is_expected.not_to be_able_to(:edit, Study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.not_to be_able_to(:activate, Study) }
    it { is_expected.not_to be_able_to(:deactivate, Study) }
    it { is_expected.to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.not_to be_able_to(:accession, Study) }
    it { is_expected.not_to be_able_to(:request_additional_with, Study) }
    it { is_expected.not_to be_able_to(:grant_role, Study) }
    it { is_expected.not_to be_able_to(:remove_role, Study) }

    # Submission
    it { is_expected.to be_able_to(:create, Submission) }
    it { is_expected.to be_able_to(:read, Submission) }
    it { is_expected.not_to be_able_to(:edit, Submission) }
    it { is_expected.not_to be_able_to(:delete, Submission) }
    it { is_expected.not_to be_able_to(:change_priority, Submission) }
    it { is_expected.to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.not_to be_able_to(:create, Supplier) }
    it { is_expected.not_to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.not_to be_able_to(:create, TagGroup) }
    it { is_expected.to be_able_to(:read, TagGroup) }
    it { is_expected.not_to be_able_to(:edit, TagGroup) }
    it { is_expected.not_to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.not_to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.not_to be_able_to(:administer, User) }
    it { is_expected.to be_able_to(:edit, User) }
    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:projects, User) }
    it { is_expected.to be_able_to(:study_reports, User) }
    it { is_expected.not_to be_able_to(:create, User) }
    it { is_expected.not_to be_able_to(:delete, User) }
  end

  context 'when the user has the role "follower"' do
    let(:user) { build :user, :with_role, role_name: 'follower' }
    let(:authorized_project) { build :project, :with_follower, follower: user }
    let(:unauthorized_project) { build :project }
    let(:authorized_study) { build :study, :with_follower, follower: user }
    let(:unauthorized_study) { build :study }

    # AssetGroup
    it { is_expected.not_to be_able_to(:create, AssetGroup) }
    it { is_expected.not_to be_able_to(:edit, AssetGroup) }
    it { is_expected.not_to be_able_to(:read, AssetGroup) }
    it { is_expected.not_to be_able_to(:delete, AssetGroup) }
    it { is_expected.not_to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.not_to be_able_to(:create, BaitLibrary) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.not_to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.not_to be_able_to(:create, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:read, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.not_to be_able_to(:create, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:read, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.not_to be_able_to(:rollback, Batch) }
    it { is_expected.to be_able_to(:edit, Batch) }
    it { is_expected.to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.to be_able_to(:print, Batch) }
    it { is_expected.to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.to be_able_to(:create, Comment) }
    it { is_expected.to be_able_to(:delete, Comment) }
    it { is_expected.to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.not_to be_able_to(:create, CustomText) }
    it { is_expected.not_to be_able_to(:edit, CustomText) }
    it { is_expected.not_to be_able_to(:read, CustomText) }
    it { is_expected.not_to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.not_to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.not_to be_able_to(:create, FacultySponsor) }
    it { is_expected.not_to be_able_to(:edit, FacultySponsor) }
    it { is_expected.not_to be_able_to(:read, FacultySponsor) }
    it { is_expected.not_to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.not_to be_able_to(:create, GelsController) }
    it { is_expected.not_to be_able_to(:edit, GelsController) }
    it { is_expected.not_to be_able_to(:read, GelsController) }
    it { is_expected.not_to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.not_to be_able_to(:rename, Labware) }
    it { is_expected.not_to be_able_to(:change_purpose, Labware) }
    it { is_expected.not_to be_able_to(:edit, Labware) }
    it { is_expected.not_to be_able_to(:create, Labware) }
    it { is_expected.not_to be_able_to(:read, Labware) }
    it { is_expected.not_to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.not_to be_able_to(:create, Order) }
    it { is_expected.not_to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.not_to be_able_to(:activate, Pipeline) }
    it { is_expected.not_to be_able_to(:deactivate, Pipeline) }
    it { is_expected.not_to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.not_to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.not_to be_able_to(:create, PlatePurpose) }
    it { is_expected.not_to be_able_to(:new, PlatePurpose) }
    it { is_expected.not_to be_able_to(:edit, PlatePurpose) }
    it { is_expected.not_to be_able_to(:read, PlatePurpose) }
    it { is_expected.not_to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.not_to be_able_to(:read, PlateTemplate) }
    it { is_expected.not_to be_able_to(:create, PlateTemplate) }
    it { is_expected.not_to be_able_to(:edit, PlateTemplate) }
    it { is_expected.not_to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.not_to be_able_to(:create, PrimerPanel) }
    it { is_expected.not_to be_able_to(:edit, PrimerPanel) }
    it { is_expected.not_to be_able_to(:read, PrimerPanel) }
    it { is_expected.not_to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.not_to be_able_to(:create, Program) }
    it { is_expected.not_to be_able_to(:edit, Program) }
    it { is_expected.not_to be_able_to(:read, Program) }
    it { is_expected.not_to be_able_to(:delete, Program) }

    # Project
    it { is_expected.not_to be_able_to(:administer, Project) }
    it { is_expected.not_to be_able_to(:administer, authorized_project) }
    it { is_expected.not_to be_able_to(:administer, unauthorized_project) }
    it { is_expected.not_to be_able_to(:edit, Project) }
    it { is_expected.not_to be_able_to(:edit, authorized_project) }
    it { is_expected.not_to be_able_to(:edit, unauthorized_project) }
    it { is_expected.not_to be_able_to(:create, Project) }
    it { is_expected.not_to be_able_to(:create, authorized_project) }
    it { is_expected.not_to be_able_to(:create, unauthorized_project) }
    it { is_expected.to be_able_to(:create_submission, Project) }
    it { is_expected.not_to be_able_to(:create_submission, authorized_project) }
    it { is_expected.not_to be_able_to(:create_submission, unauthorized_project) }
    it { is_expected.not_to be_able_to(:read, Project) }
    it { is_expected.not_to be_able_to(:read, authorized_project) }
    it { is_expected.not_to be_able_to(:read, unauthorized_project) }
    it { is_expected.not_to be_able_to(:delete, Project) }
    it { is_expected.not_to be_able_to(:delete, authorized_project) }
    it { is_expected.not_to be_able_to(:delete, unauthorized_project) }

    # Purpose
    it { is_expected.not_to be_able_to(:create, Purpose) }
    it { is_expected.not_to be_able_to(:edit, Purpose) }
    it { is_expected.not_to be_able_to(:read, Purpose) }
    it { is_expected.not_to be_able_to(:delete, Purpose) }
    it { is_expected.not_to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.not_to be_able_to(:create, QcDecision) }
    it { is_expected.not_to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.not_to be_able_to(:edit, Receptacle) }
    it { is_expected.not_to be_able_to(:close, Receptacle) }
    it { is_expected.not_to be_able_to(:create, Receptacle) }
    it { is_expected.not_to be_able_to(:read, Receptacle) }
    it { is_expected.not_to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.not_to be_able_to(:create, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.to be_able_to(:read, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.not_to be_able_to(:create_additional, Request) }
    it { is_expected.not_to be_able_to(:copy, Request) }
    it { is_expected.not_to be_able_to(:cancel, Request) }
    it { is_expected.not_to be_able_to(:change_priority, Request) }
    it { is_expected.not_to be_able_to(:see_previously_failed, Request) }
    it { is_expected.not_to be_able_to(:edit_additional, Request) }
    it { is_expected.not_to be_able_to(:reset_qc_information, Request) }
    it { is_expected.not_to be_able_to(:edit, Request) }
    it { is_expected.not_to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.not_to be_able_to(:create, Robot) }
    it { is_expected.not_to be_able_to(:edit, Robot) }
    it { is_expected.to be_able_to(:read, Robot) }
    it { is_expected.not_to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.not_to be_able_to(:create, RobotProperty) }
    it { is_expected.not_to be_able_to(:edit, RobotProperty) }
    it { is_expected.not_to be_able_to(:read, RobotProperty) }
    it { is_expected.not_to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.not_to be_able_to(:create, Role) }
    it { is_expected.not_to be_able_to(:administer, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.to be_able_to(:edit, Sample) }
    it { is_expected.to be_able_to(:release, Sample) }
    it { is_expected.to be_able_to(:accession, Sample) }
    it { is_expected.not_to be_able_to(:update_released, Sample) }

    # SampleLogisticsController
    it { is_expected.not_to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.not_to be_able_to(:create, SampleManifest) }
    it { is_expected.not_to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.not_to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.not_to be_able_to(:administer, Study) }
    it { is_expected.not_to be_able_to(:administer, authorized_study) }
    it { is_expected.not_to be_able_to(:administer, unauthorized_study) }
    it { is_expected.not_to be_able_to(:unlink_sample, Study) }
    it { is_expected.not_to be_able_to(:unlink_sample, authorized_study) }
    it { is_expected.not_to be_able_to(:unlink_sample, unauthorized_study) }
    it { is_expected.not_to be_able_to(:link_sample, Study) }
    it { is_expected.not_to be_able_to(:link_sample, authorized_study) }
    it { is_expected.not_to be_able_to(:link_sample, unauthorized_study) }
    it { is_expected.not_to be_able_to(:edit, Study) }
    it { is_expected.not_to be_able_to(:edit, authorized_study) }
    it { is_expected.not_to be_able_to(:edit, unauthorized_study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.not_to be_able_to(:create, authorized_study) }
    it { is_expected.not_to be_able_to(:create, unauthorized_study) }
    it { is_expected.not_to be_able_to(:activate, Study) }
    it { is_expected.not_to be_able_to(:activate, authorized_study) }
    it { is_expected.not_to be_able_to(:activate, unauthorized_study) }
    it { is_expected.not_to be_able_to(:deactivate, Study) }
    it { is_expected.not_to be_able_to(:deactivate, authorized_study) }
    it { is_expected.not_to be_able_to(:deactivate, unauthorized_study) }
    it { is_expected.to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.not_to be_able_to(:print_asset_group_labels, authorized_study) }
    it { is_expected.not_to be_able_to(:print_asset_group_labels, unauthorized_study) }
    it { is_expected.not_to be_able_to(:accession, Study) }
    it { is_expected.not_to be_able_to(:accession, authorized_study) }
    it { is_expected.not_to be_able_to(:accession, unauthorized_study) }
    it { is_expected.not_to be_able_to(:request_additional_with, Study) }
    it { is_expected.not_to be_able_to(:request_additional_with, authorized_study) }
    it { is_expected.not_to be_able_to(:request_additional_with, unauthorized_study) }
    it { is_expected.not_to be_able_to(:grant_role, Study) }
    it { is_expected.not_to be_able_to(:grant_role, authorized_study) }
    it { is_expected.not_to be_able_to(:grant_role, unauthorized_study) }
    it { is_expected.not_to be_able_to(:remove_role, Study) }
    it { is_expected.not_to be_able_to(:remove_role, authorized_study) }
    it { is_expected.not_to be_able_to(:remove_role, unauthorized_study) }

    # Submission
    it { is_expected.to be_able_to(:create, Submission) }
    it { is_expected.to be_able_to(:read, Submission) }
    it { is_expected.not_to be_able_to(:edit, Submission) }
    it { is_expected.not_to be_able_to(:delete, Submission) }
    it { is_expected.not_to be_able_to(:change_priority, Submission) }
    it { is_expected.to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.not_to be_able_to(:create, Supplier) }
    it { is_expected.not_to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.not_to be_able_to(:create, TagGroup) }
    it { is_expected.to be_able_to(:read, TagGroup) }
    it { is_expected.not_to be_able_to(:edit, TagGroup) }
    it { is_expected.not_to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.not_to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.not_to be_able_to(:administer, User) }
    it { is_expected.to be_able_to(:edit, User) }
    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:projects, User) }
    it { is_expected.to be_able_to(:study_reports, User) }
    it { is_expected.not_to be_able_to(:create, User) }
    it { is_expected.not_to be_able_to(:delete, User) }
  end

  context 'when the user has the role "lab"' do
    let(:user) { build :user, :with_role, role_name: 'lab' }

    # AssetGroup
    it { is_expected.not_to be_able_to(:create, AssetGroup) }
    it { is_expected.not_to be_able_to(:edit, AssetGroup) }
    it { is_expected.not_to be_able_to(:read, AssetGroup) }
    it { is_expected.not_to be_able_to(:delete, AssetGroup) }
    it { is_expected.not_to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.not_to be_able_to(:create, BaitLibrary) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.not_to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.not_to be_able_to(:create, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:read, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.not_to be_able_to(:create, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:read, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.not_to be_able_to(:rollback, Batch) }
    it { is_expected.to be_able_to(:edit, Batch) }
    it { is_expected.to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.to be_able_to(:print, Batch) }
    it { is_expected.to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.to be_able_to(:create, Comment) }
    it { is_expected.to be_able_to(:delete, Comment) }
    it { is_expected.to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.not_to be_able_to(:create, CustomText) }
    it { is_expected.not_to be_able_to(:edit, CustomText) }
    it { is_expected.not_to be_able_to(:read, CustomText) }
    it { is_expected.not_to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.not_to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.not_to be_able_to(:create, FacultySponsor) }
    it { is_expected.not_to be_able_to(:edit, FacultySponsor) }
    it { is_expected.not_to be_able_to(:read, FacultySponsor) }
    it { is_expected.not_to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.not_to be_able_to(:create, GelsController) }
    it { is_expected.not_to be_able_to(:edit, GelsController) }
    it { is_expected.not_to be_able_to(:read, GelsController) }
    it { is_expected.not_to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.not_to be_able_to(:rename, Labware) }
    it { is_expected.not_to be_able_to(:change_purpose, Labware) }
    it { is_expected.not_to be_able_to(:edit, Labware) }
    it { is_expected.not_to be_able_to(:create, Labware) }
    it { is_expected.not_to be_able_to(:read, Labware) }
    it { is_expected.not_to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.not_to be_able_to(:create, Order) }
    it { is_expected.not_to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.not_to be_able_to(:activate, Pipeline) }
    it { is_expected.not_to be_able_to(:deactivate, Pipeline) }
    it { is_expected.not_to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.not_to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.not_to be_able_to(:create, PlatePurpose) }
    it { is_expected.not_to be_able_to(:new, PlatePurpose) }
    it { is_expected.not_to be_able_to(:edit, PlatePurpose) }
    it { is_expected.not_to be_able_to(:read, PlatePurpose) }
    it { is_expected.not_to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.not_to be_able_to(:read, PlateTemplate) }
    it { is_expected.not_to be_able_to(:create, PlateTemplate) }
    it { is_expected.not_to be_able_to(:edit, PlateTemplate) }
    it { is_expected.not_to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.not_to be_able_to(:create, PrimerPanel) }
    it { is_expected.not_to be_able_to(:edit, PrimerPanel) }
    it { is_expected.not_to be_able_to(:read, PrimerPanel) }
    it { is_expected.not_to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.not_to be_able_to(:create, Program) }
    it { is_expected.not_to be_able_to(:edit, Program) }
    it { is_expected.not_to be_able_to(:read, Program) }
    it { is_expected.not_to be_able_to(:delete, Program) }

    # Project
    it { is_expected.not_to be_able_to(:administer, Project) }
    it { is_expected.not_to be_able_to(:edit, Project) }
    it { is_expected.not_to be_able_to(:create, Project) }
    it { is_expected.to be_able_to(:create_submission, Project) }
    it { is_expected.not_to be_able_to(:read, Project) }
    it { is_expected.not_to be_able_to(:delete, Project) }

    # Purpose
    it { is_expected.not_to be_able_to(:create, Purpose) }
    it { is_expected.not_to be_able_to(:edit, Purpose) }
    it { is_expected.not_to be_able_to(:read, Purpose) }
    it { is_expected.not_to be_able_to(:delete, Purpose) }
    it { is_expected.not_to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.not_to be_able_to(:create, QcDecision) }
    it { is_expected.not_to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.not_to be_able_to(:edit, Receptacle) }
    it { is_expected.not_to be_able_to(:close, Receptacle) }
    it { is_expected.not_to be_able_to(:create, Receptacle) }
    it { is_expected.not_to be_able_to(:read, Receptacle) }
    it { is_expected.not_to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.not_to be_able_to(:create, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.to be_able_to(:read, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.not_to be_able_to(:create_additional, Request) }
    it { is_expected.not_to be_able_to(:copy, Request) }
    it { is_expected.not_to be_able_to(:cancel, Request) }
    it { is_expected.not_to be_able_to(:change_priority, Request) }
    it { is_expected.not_to be_able_to(:see_previously_failed, Request) }
    it { is_expected.not_to be_able_to(:edit_additional, Request) }
    it { is_expected.not_to be_able_to(:reset_qc_information, Request) }
    it { is_expected.not_to be_able_to(:edit, Request) }
    it { is_expected.not_to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.not_to be_able_to(:create, Robot) }
    it { is_expected.not_to be_able_to(:edit, Robot) }
    it { is_expected.to be_able_to(:read, Robot) }
    it { is_expected.not_to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.not_to be_able_to(:create, RobotProperty) }
    it { is_expected.not_to be_able_to(:edit, RobotProperty) }
    it { is_expected.not_to be_able_to(:read, RobotProperty) }
    it { is_expected.not_to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.not_to be_able_to(:create, Role) }
    it { is_expected.not_to be_able_to(:administer, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.to be_able_to(:edit, Sample) }
    it { is_expected.to be_able_to(:release, Sample) }
    it { is_expected.to be_able_to(:accession, Sample) }
    it { is_expected.not_to be_able_to(:update_released, Sample) }

    # SampleLogisticsController
    it { is_expected.not_to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.not_to be_able_to(:create, SampleManifest) }
    it { is_expected.not_to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.not_to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.not_to be_able_to(:administer, Study) }
    it { is_expected.not_to be_able_to(:unlink_sample, Study) }
    it { is_expected.not_to be_able_to(:link_sample, Study) }
    it { is_expected.not_to be_able_to(:edit, Study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.not_to be_able_to(:activate, Study) }
    it { is_expected.not_to be_able_to(:deactivate, Study) }
    it { is_expected.to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.not_to be_able_to(:accession, Study) }
    it { is_expected.not_to be_able_to(:request_additional_with, Study) }
    it { is_expected.not_to be_able_to(:grant_role, Study) }
    it { is_expected.not_to be_able_to(:remove_role, Study) }

    # Submission
    it { is_expected.to be_able_to(:create, Submission) }
    it { is_expected.to be_able_to(:read, Submission) }
    it { is_expected.not_to be_able_to(:edit, Submission) }
    it { is_expected.not_to be_able_to(:delete, Submission) }
    it { is_expected.not_to be_able_to(:change_priority, Submission) }
    it { is_expected.to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.not_to be_able_to(:create, Supplier) }
    it { is_expected.not_to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.not_to be_able_to(:create, TagGroup) }
    it { is_expected.to be_able_to(:read, TagGroup) }
    it { is_expected.not_to be_able_to(:edit, TagGroup) }
    it { is_expected.not_to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.not_to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.not_to be_able_to(:administer, User) }
    it { is_expected.to be_able_to(:edit, User) }
    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:projects, User) }
    it { is_expected.to be_able_to(:study_reports, User) }
    it { is_expected.not_to be_able_to(:create, User) }
    it { is_expected.not_to be_able_to(:delete, User) }
  end

  context 'when the user has the role "lab_manager"' do
    let(:user) { build :user, :with_role, role_name: 'lab_manager' }

    # AssetGroup
    it { is_expected.not_to be_able_to(:create, AssetGroup) }
    it { is_expected.not_to be_able_to(:edit, AssetGroup) }
    it { is_expected.not_to be_able_to(:read, AssetGroup) }
    it { is_expected.not_to be_able_to(:delete, AssetGroup) }
    it { is_expected.not_to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.not_to be_able_to(:create, BaitLibrary) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.not_to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.not_to be_able_to(:create, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:read, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.not_to be_able_to(:create, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:read, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.not_to be_able_to(:rollback, Batch) }
    it { is_expected.to be_able_to(:edit, Batch) }
    it { is_expected.to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.to be_able_to(:print, Batch) }
    it { is_expected.to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.to be_able_to(:create, Comment) }
    it { is_expected.to be_able_to(:delete, Comment) }
    it { is_expected.to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.not_to be_able_to(:create, CustomText) }
    it { is_expected.not_to be_able_to(:edit, CustomText) }
    it { is_expected.not_to be_able_to(:read, CustomText) }
    it { is_expected.not_to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.not_to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.not_to be_able_to(:create, FacultySponsor) }
    it { is_expected.not_to be_able_to(:edit, FacultySponsor) }
    it { is_expected.not_to be_able_to(:read, FacultySponsor) }
    it { is_expected.not_to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.not_to be_able_to(:create, GelsController) }
    it { is_expected.not_to be_able_to(:edit, GelsController) }
    it { is_expected.not_to be_able_to(:read, GelsController) }
    it { is_expected.not_to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.to be_able_to(:rename, Labware) }
    it { is_expected.to be_able_to(:change_purpose, Labware) }
    it { is_expected.to be_able_to(:edit, Labware) }
    it { is_expected.to be_able_to(:create, Labware) }
    it { is_expected.to be_able_to(:read, Labware) }
    it { is_expected.to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.not_to be_able_to(:create, Order) }
    it { is_expected.not_to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.not_to be_able_to(:activate, Pipeline) }
    it { is_expected.not_to be_able_to(:deactivate, Pipeline) }
    it { is_expected.to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.not_to be_able_to(:create, PlatePurpose) }
    it { is_expected.not_to be_able_to(:new, PlatePurpose) }
    it { is_expected.not_to be_able_to(:edit, PlatePurpose) }
    it { is_expected.not_to be_able_to(:read, PlatePurpose) }
    it { is_expected.not_to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.to be_able_to(:read, PlateTemplate) }
    it { is_expected.to be_able_to(:create, PlateTemplate) }
    it { is_expected.to be_able_to(:edit, PlateTemplate) }
    it { is_expected.to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.not_to be_able_to(:create, PrimerPanel) }
    it { is_expected.not_to be_able_to(:edit, PrimerPanel) }
    it { is_expected.not_to be_able_to(:read, PrimerPanel) }
    it { is_expected.not_to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.not_to be_able_to(:create, Program) }
    it { is_expected.not_to be_able_to(:edit, Program) }
    it { is_expected.not_to be_able_to(:read, Program) }
    it { is_expected.not_to be_able_to(:delete, Program) }

    # Project
    it { is_expected.not_to be_able_to(:administer, Project) }
    it { is_expected.not_to be_able_to(:edit, Project) }
    it { is_expected.not_to be_able_to(:create, Project) }
    it { is_expected.to be_able_to(:create_submission, Project) }
    it { is_expected.not_to be_able_to(:read, Project) }
    it { is_expected.not_to be_able_to(:delete, Project) }

    # Purpose
    it { is_expected.not_to be_able_to(:create, Purpose) }
    it { is_expected.not_to be_able_to(:edit, Purpose) }
    it { is_expected.not_to be_able_to(:read, Purpose) }
    it { is_expected.not_to be_able_to(:delete, Purpose) }
    it { is_expected.not_to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.not_to be_able_to(:create, QcDecision) }
    it { is_expected.not_to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.not_to be_able_to(:edit, Receptacle) }
    it { is_expected.not_to be_able_to(:close, Receptacle) }
    it { is_expected.not_to be_able_to(:create, Receptacle) }
    it { is_expected.not_to be_able_to(:read, Receptacle) }
    it { is_expected.not_to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.not_to be_able_to(:create, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.to be_able_to(:read, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.not_to be_able_to(:create_additional, Request) }
    it { is_expected.not_to be_able_to(:copy, Request) }
    it { is_expected.not_to be_able_to(:cancel, Request) }
    it { is_expected.to be_able_to(:change_priority, Request) }
    it { is_expected.to be_able_to(:see_previously_failed, Request) }
    it { is_expected.not_to be_able_to(:edit_additional, Request) }
    it { is_expected.not_to be_able_to(:reset_qc_information, Request) }
    it { is_expected.not_to be_able_to(:edit, Request) }
    it { is_expected.not_to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.not_to be_able_to(:create, Robot) }
    it { is_expected.not_to be_able_to(:edit, Robot) }
    it { is_expected.to be_able_to(:read, Robot) }
    it { is_expected.not_to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.not_to be_able_to(:create, RobotProperty) }
    it { is_expected.not_to be_able_to(:edit, RobotProperty) }
    it { is_expected.not_to be_able_to(:read, RobotProperty) }
    it { is_expected.not_to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.not_to be_able_to(:create, Role) }
    it { is_expected.not_to be_able_to(:administer, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.to be_able_to(:edit, Sample) }
    it { is_expected.to be_able_to(:release, Sample) }
    it { is_expected.to be_able_to(:accession, Sample) }
    it { is_expected.not_to be_able_to(:update_released, Sample) }

    # SampleLogisticsController
    it { is_expected.not_to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.not_to be_able_to(:create, SampleManifest) }
    it { is_expected.not_to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.not_to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.not_to be_able_to(:administer, Study) }
    it { is_expected.not_to be_able_to(:unlink_sample, Study) }
    it { is_expected.not_to be_able_to(:link_sample, Study) }
    it { is_expected.not_to be_able_to(:edit, Study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.not_to be_able_to(:activate, Study) }
    it { is_expected.not_to be_able_to(:deactivate, Study) }
    it { is_expected.to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.not_to be_able_to(:accession, Study) }
    it { is_expected.not_to be_able_to(:request_additional_with, Study) }
    it { is_expected.not_to be_able_to(:grant_role, Study) }
    it { is_expected.not_to be_able_to(:remove_role, Study) }

    # Submission
    it { is_expected.to be_able_to(:create, Submission) }
    it { is_expected.to be_able_to(:read, Submission) }
    it { is_expected.not_to be_able_to(:edit, Submission) }
    it { is_expected.not_to be_able_to(:delete, Submission) }
    it { is_expected.to be_able_to(:change_priority, Submission) }
    it { is_expected.to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.not_to be_able_to(:create, Supplier) }
    it { is_expected.not_to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.not_to be_able_to(:create, TagGroup) }
    it { is_expected.to be_able_to(:read, TagGroup) }
    it { is_expected.not_to be_able_to(:edit, TagGroup) }
    it { is_expected.not_to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.not_to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.not_to be_able_to(:administer, User) }
    it { is_expected.to be_able_to(:edit, User) }
    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:projects, User) }
    it { is_expected.to be_able_to(:study_reports, User) }
    it { is_expected.not_to be_able_to(:create, User) }
    it { is_expected.not_to be_able_to(:delete, User) }
  end

  context 'when the user has the role "manager"' do
    let(:user) { build :user, :with_role, role_name: 'manager' }
    let(:authorized_project) { build :project, :with_manager, manager: user }
    let(:unauthorized_project) { build :project }
    let(:authorized_study) { build :study, :with_manager, manager: user }
    let(:unauthorized_study) { build :study }

    # AssetGroup
    it { is_expected.to be_able_to(:create, AssetGroup) }
    it { is_expected.not_to be_able_to(:edit, AssetGroup) }
    it { is_expected.not_to be_able_to(:read, AssetGroup) }
    it { is_expected.not_to be_able_to(:delete, AssetGroup) }
    it { is_expected.to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.not_to be_able_to(:create, BaitLibrary) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.not_to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.not_to be_able_to(:create, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:read, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.not_to be_able_to(:create, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:read, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.not_to be_able_to(:rollback, Batch) }
    it { is_expected.to be_able_to(:edit, Batch) }
    it { is_expected.to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.to be_able_to(:print, Batch) }
    it { is_expected.to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.to be_able_to(:create, Comment) }
    it { is_expected.to be_able_to(:delete, Comment) }
    it { is_expected.to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.not_to be_able_to(:create, CustomText) }
    it { is_expected.not_to be_able_to(:edit, CustomText) }
    it { is_expected.not_to be_able_to(:read, CustomText) }
    it { is_expected.not_to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.not_to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.not_to be_able_to(:create, FacultySponsor) }
    it { is_expected.not_to be_able_to(:edit, FacultySponsor) }
    it { is_expected.not_to be_able_to(:read, FacultySponsor) }
    it { is_expected.not_to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.to be_able_to(:create, GelsController) }
    it { is_expected.to be_able_to(:edit, GelsController) }
    it { is_expected.to be_able_to(:read, GelsController) }
    it { is_expected.to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.to be_able_to(:rename, Labware) }
    it { is_expected.to be_able_to(:change_purpose, Labware) }
    it { is_expected.to be_able_to(:edit, Labware) }
    it { is_expected.to be_able_to(:create, Labware) }
    it { is_expected.to be_able_to(:read, Labware) }
    it { is_expected.to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.to be_able_to(:create, Order) }
    it { is_expected.to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.not_to be_able_to(:activate, Pipeline) }
    it { is_expected.not_to be_able_to(:deactivate, Pipeline) }
    it { is_expected.not_to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.not_to be_able_to(:create, PlatePurpose) }
    it { is_expected.not_to be_able_to(:new, PlatePurpose) }
    it { is_expected.not_to be_able_to(:edit, PlatePurpose) }
    it { is_expected.not_to be_able_to(:read, PlatePurpose) }
    it { is_expected.not_to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.to be_able_to(:read, PlateTemplate) }
    it { is_expected.to be_able_to(:create, PlateTemplate) }
    it { is_expected.to be_able_to(:edit, PlateTemplate) }
    it { is_expected.to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.not_to be_able_to(:create, PrimerPanel) }
    it { is_expected.not_to be_able_to(:edit, PrimerPanel) }
    it { is_expected.not_to be_able_to(:read, PrimerPanel) }
    it { is_expected.not_to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.not_to be_able_to(:create, Program) }
    it { is_expected.not_to be_able_to(:edit, Program) }
    it { is_expected.not_to be_able_to(:read, Program) }
    it { is_expected.not_to be_able_to(:delete, Program) }

    # Project
    it { is_expected.not_to be_able_to(:administer, Project) }
    it { is_expected.not_to be_able_to(:administer, authorized_project) }
    it { is_expected.not_to be_able_to(:administer, unauthorized_project) }
    it { is_expected.to be_able_to(:edit, Project) }
    it { is_expected.not_to be_able_to(:edit, authorized_project) }
    it { is_expected.not_to be_able_to(:edit, unauthorized_project) }
    it { is_expected.not_to be_able_to(:create, Project) }
    it { is_expected.not_to be_able_to(:create, authorized_project) }
    it { is_expected.not_to be_able_to(:create, unauthorized_project) }
    it { is_expected.to be_able_to(:create_submission, Project) }
    it { is_expected.to be_able_to(:create_submission, authorized_project) }
    it { is_expected.to be_able_to(:create_submission, unauthorized_project) }
    it { is_expected.not_to be_able_to(:read, Project) }
    it { is_expected.not_to be_able_to(:read, authorized_project) }
    it { is_expected.not_to be_able_to(:read, unauthorized_project) }
    it { is_expected.not_to be_able_to(:delete, Project) }
    it { is_expected.not_to be_able_to(:delete, authorized_project) }
    it { is_expected.not_to be_able_to(:delete, unauthorized_project) }

    # Purpose
    it { is_expected.not_to be_able_to(:create, Purpose) }
    it { is_expected.not_to be_able_to(:edit, Purpose) }
    it { is_expected.not_to be_able_to(:read, Purpose) }
    it { is_expected.not_to be_able_to(:delete, Purpose) }
    it { is_expected.not_to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.not_to be_able_to(:create, QcDecision) }
    it { is_expected.not_to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.to be_able_to(:edit, Receptacle) }
    it { is_expected.to be_able_to(:close, Receptacle) }
    it { is_expected.to be_able_to(:create, Receptacle) }
    it { is_expected.to be_able_to(:read, Receptacle) }
    it { is_expected.to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.not_to be_able_to(:create, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.to be_able_to(:read, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.to be_able_to(:create_additional, Request) }
    it { is_expected.to be_able_to(:copy, Request) }
    it { is_expected.to be_able_to(:cancel, Request) }
    it { is_expected.not_to be_able_to(:change_priority, Request) }
    it { is_expected.not_to be_able_to(:see_previously_failed, Request) }
    it { is_expected.not_to be_able_to(:edit_additional, Request) }
    it { is_expected.not_to be_able_to(:reset_qc_information, Request) }
    it { is_expected.not_to be_able_to(:edit, Request) }
    it { is_expected.to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.not_to be_able_to(:create, Robot) }
    it { is_expected.not_to be_able_to(:edit, Robot) }
    it { is_expected.to be_able_to(:read, Robot) }
    it { is_expected.not_to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.not_to be_able_to(:create, RobotProperty) }
    it { is_expected.not_to be_able_to(:edit, RobotProperty) }
    it { is_expected.not_to be_able_to(:read, RobotProperty) }
    it { is_expected.not_to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.not_to be_able_to(:create, Role) }
    it { is_expected.not_to be_able_to(:administer, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.to be_able_to(:edit, Sample) }
    it { is_expected.to be_able_to(:release, Sample) }
    it { is_expected.to be_able_to(:accession, Sample) }
    it { is_expected.not_to be_able_to(:update_released, Sample) }

    # SampleLogisticsController
    it { is_expected.to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.to be_able_to(:create, SampleManifest) }
    it { is_expected.to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.not_to be_able_to(:administer, Study) }
    it { is_expected.not_to be_able_to(:administer, authorized_study) }
    it { is_expected.not_to be_able_to(:administer, unauthorized_study) }
    it { is_expected.to be_able_to(:unlink_sample, Study) }
    it { is_expected.not_to be_able_to(:unlink_sample, authorized_study) }
    it { is_expected.not_to be_able_to(:unlink_sample, unauthorized_study) }
    it { is_expected.to be_able_to(:link_sample, Study) }
    it { is_expected.not_to be_able_to(:link_sample, authorized_study) }
    it { is_expected.not_to be_able_to(:link_sample, unauthorized_study) }
    it { is_expected.to be_able_to(:edit, Study) }
    it { is_expected.to be_able_to(:edit, authorized_study) }
    it { is_expected.to be_able_to(:edit, unauthorized_study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.not_to be_able_to(:create, authorized_study) }
    it { is_expected.not_to be_able_to(:create, unauthorized_study) }
    it { is_expected.to be_able_to(:activate, Study) }
    it { is_expected.to be_able_to(:activate, authorized_study) }
    it { is_expected.to be_able_to(:activate, unauthorized_study) }
    it { is_expected.to be_able_to(:deactivate, Study) }
    it { is_expected.to be_able_to(:deactivate, authorized_study) }
    it { is_expected.to be_able_to(:deactivate, unauthorized_study) }
    it { is_expected.to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.not_to be_able_to(:print_asset_group_labels, authorized_study) }
    it { is_expected.not_to be_able_to(:print_asset_group_labels, unauthorized_study) }
    it { is_expected.to be_able_to(:accession, Study) }
    it { is_expected.not_to be_able_to(:accession, authorized_study) }
    it { is_expected.not_to be_able_to(:accession, unauthorized_study) }
    it { is_expected.to be_able_to(:request_additional_with, Study) }
    it { is_expected.not_to be_able_to(:request_additional_with, authorized_study) }
    it { is_expected.not_to be_able_to(:request_additional_with, unauthorized_study) }
    it { is_expected.not_to be_able_to(:grant_role, Study) }
    it { is_expected.not_to be_able_to(:grant_role, authorized_study) }
    it { is_expected.not_to be_able_to(:grant_role, unauthorized_study) }
    it { is_expected.not_to be_able_to(:remove_role, Study) }
    it { is_expected.not_to be_able_to(:remove_role, authorized_study) }
    it { is_expected.not_to be_able_to(:remove_role, unauthorized_study) }

    # Submission
    it { is_expected.to be_able_to(:create, Submission) }
    it { is_expected.to be_able_to(:read, Submission) }
    it { is_expected.not_to be_able_to(:edit, Submission) }
    it { is_expected.not_to be_able_to(:delete, Submission) }
    it { is_expected.not_to be_able_to(:change_priority, Submission) }
    it { is_expected.to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.to be_able_to(:create, Supplier) }
    it { is_expected.to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.not_to be_able_to(:create, TagGroup) }
    it { is_expected.to be_able_to(:read, TagGroup) }
    it { is_expected.not_to be_able_to(:edit, TagGroup) }
    it { is_expected.not_to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.not_to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.not_to be_able_to(:administer, User) }
    it { is_expected.to be_able_to(:edit, User) }
    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:projects, User) }
    it { is_expected.to be_able_to(:study_reports, User) }
    it { is_expected.not_to be_able_to(:create, User) }
    it { is_expected.not_to be_able_to(:delete, User) }
  end

  context 'when the user has the role "owner"' do
    let(:user) { build :user, :with_role, role_name: 'owner' }
    let(:authorized_project) { build :project, :with_owner, owner: user }
    let(:unauthorized_project) { build :project }
    let(:authorized_sample) { build :sample, :with_owner, owner: user }
    let(:unauthorized_sample) { build :sample }
    let(:authorized_study) { build :study, :with_owner, owner: user }
    let(:unauthorized_study) { build :study }

    # AssetGroup
    it { is_expected.not_to be_able_to(:create, AssetGroup) }
    it { is_expected.not_to be_able_to(:edit, AssetGroup) }
    it { is_expected.not_to be_able_to(:read, AssetGroup) }
    it { is_expected.not_to be_able_to(:delete, AssetGroup) }
    it { is_expected.not_to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.not_to be_able_to(:create, BaitLibrary) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.not_to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.not_to be_able_to(:create, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:read, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.not_to be_able_to(:create, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:read, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.not_to be_able_to(:rollback, Batch) }
    it { is_expected.to be_able_to(:edit, Batch) }
    it { is_expected.to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.to be_able_to(:print, Batch) }
    it { is_expected.to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.to be_able_to(:create, Comment) }
    it { is_expected.to be_able_to(:delete, Comment) }
    it { is_expected.to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.not_to be_able_to(:create, CustomText) }
    it { is_expected.not_to be_able_to(:edit, CustomText) }
    it { is_expected.not_to be_able_to(:read, CustomText) }
    it { is_expected.not_to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.not_to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.not_to be_able_to(:create, FacultySponsor) }
    it { is_expected.not_to be_able_to(:edit, FacultySponsor) }
    it { is_expected.not_to be_able_to(:read, FacultySponsor) }
    it { is_expected.not_to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.not_to be_able_to(:create, GelsController) }
    it { is_expected.not_to be_able_to(:edit, GelsController) }
    it { is_expected.not_to be_able_to(:read, GelsController) }
    it { is_expected.not_to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.not_to be_able_to(:rename, Labware) }
    it { is_expected.not_to be_able_to(:change_purpose, Labware) }
    it { is_expected.not_to be_able_to(:edit, Labware) }
    it { is_expected.not_to be_able_to(:create, Labware) }
    it { is_expected.not_to be_able_to(:read, Labware) }
    it { is_expected.not_to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.not_to be_able_to(:create, Order) }
    it { is_expected.not_to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.not_to be_able_to(:activate, Pipeline) }
    it { is_expected.not_to be_able_to(:deactivate, Pipeline) }
    it { is_expected.not_to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.not_to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.not_to be_able_to(:create, PlatePurpose) }
    it { is_expected.not_to be_able_to(:new, PlatePurpose) }
    it { is_expected.not_to be_able_to(:edit, PlatePurpose) }
    it { is_expected.not_to be_able_to(:read, PlatePurpose) }
    it { is_expected.not_to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.not_to be_able_to(:read, PlateTemplate) }
    it { is_expected.not_to be_able_to(:create, PlateTemplate) }
    it { is_expected.not_to be_able_to(:edit, PlateTemplate) }
    it { is_expected.not_to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.not_to be_able_to(:create, PrimerPanel) }
    it { is_expected.not_to be_able_to(:edit, PrimerPanel) }
    it { is_expected.not_to be_able_to(:read, PrimerPanel) }
    it { is_expected.not_to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.not_to be_able_to(:create, Program) }
    it { is_expected.not_to be_able_to(:edit, Program) }
    it { is_expected.not_to be_able_to(:read, Program) }
    it { is_expected.not_to be_able_to(:delete, Program) }

    # Project
    it { is_expected.not_to be_able_to(:administer, Project) }
    it { is_expected.not_to be_able_to(:administer, authorized_project) }
    it { is_expected.not_to be_able_to(:administer, unauthorized_project) }
    it { is_expected.not_to be_able_to(:edit, Project) }
    it { is_expected.not_to be_able_to(:edit, authorized_project) }
    it { is_expected.not_to be_able_to(:edit, unauthorized_project) }
    it { is_expected.not_to be_able_to(:create, Project) }
    it { is_expected.not_to be_able_to(:create, authorized_project) }
    it { is_expected.not_to be_able_to(:create, unauthorized_project) }
    it { is_expected.to be_able_to(:create_submission, Project) }
    it { is_expected.not_to be_able_to(:create_submission, authorized_project) }
    it { is_expected.not_to be_able_to(:create_submission, unauthorized_project) }
    it { is_expected.not_to be_able_to(:read, Project) }
    it { is_expected.not_to be_able_to(:read, authorized_project) }
    it { is_expected.not_to be_able_to(:read, unauthorized_project) }
    it { is_expected.not_to be_able_to(:delete, Project) }
    it { is_expected.not_to be_able_to(:delete, authorized_project) }
    it { is_expected.not_to be_able_to(:delete, unauthorized_project) }

    # Purpose
    it { is_expected.not_to be_able_to(:create, Purpose) }
    it { is_expected.not_to be_able_to(:edit, Purpose) }
    it { is_expected.not_to be_able_to(:read, Purpose) }
    it { is_expected.not_to be_able_to(:delete, Purpose) }
    it { is_expected.not_to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.not_to be_able_to(:create, QcDecision) }
    it { is_expected.not_to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.not_to be_able_to(:edit, Receptacle) }
    it { is_expected.not_to be_able_to(:close, Receptacle) }
    it { is_expected.not_to be_able_to(:create, Receptacle) }
    it { is_expected.not_to be_able_to(:read, Receptacle) }
    it { is_expected.not_to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.not_to be_able_to(:create, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.to be_able_to(:read, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.not_to be_able_to(:create_additional, Request) }
    it { is_expected.not_to be_able_to(:copy, Request) }
    it { is_expected.not_to be_able_to(:cancel, Request) }
    it { is_expected.not_to be_able_to(:change_priority, Request) }
    it { is_expected.not_to be_able_to(:see_previously_failed, Request) }
    it { is_expected.not_to be_able_to(:edit_additional, Request) }
    it { is_expected.not_to be_able_to(:reset_qc_information, Request) }
    it { is_expected.not_to be_able_to(:edit, Request) }
    it { is_expected.not_to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.not_to be_able_to(:create, Robot) }
    it { is_expected.not_to be_able_to(:edit, Robot) }
    it { is_expected.to be_able_to(:read, Robot) }
    it { is_expected.not_to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.not_to be_able_to(:create, RobotProperty) }
    it { is_expected.not_to be_able_to(:edit, RobotProperty) }
    it { is_expected.not_to be_able_to(:read, RobotProperty) }
    it { is_expected.not_to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.not_to be_able_to(:create, Role) }
    it { is_expected.not_to be_able_to(:administer, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.to be_able_to(:edit, Sample) }
    it { is_expected.not_to be_able_to(:edit, authorized_sample) }
    it { is_expected.not_to be_able_to(:edit, unauthorized_sample) }
    it { is_expected.to be_able_to(:release, Sample) }
    it { is_expected.not_to be_able_to(:release, authorized_sample) }
    it { is_expected.not_to be_able_to(:release, unauthorized_sample) }
    it { is_expected.to be_able_to(:accession, Sample) }
    it { is_expected.not_to be_able_to(:accession, authorized_sample) }
    it { is_expected.not_to be_able_to(:accession, unauthorized_sample) }
    it { is_expected.not_to be_able_to(:update_released, Sample) }
    it { is_expected.not_to be_able_to(:update_released, authorized_sample) }
    it { is_expected.not_to be_able_to(:update_released, unauthorized_sample) }

    # SampleLogisticsController
    it { is_expected.not_to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.not_to be_able_to(:create, SampleManifest) }
    it { is_expected.not_to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.not_to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.not_to be_able_to(:administer, Study) }
    it { is_expected.not_to be_able_to(:administer, authorized_study) }
    it { is_expected.not_to be_able_to(:administer, unauthorized_study) }
    it { is_expected.not_to be_able_to(:unlink_sample, Study) }
    it { is_expected.not_to be_able_to(:unlink_sample, authorized_study) }
    it { is_expected.not_to be_able_to(:unlink_sample, unauthorized_study) }
    it { is_expected.not_to be_able_to(:link_sample, Study) }
    it { is_expected.not_to be_able_to(:link_sample, authorized_study) }
    it { is_expected.not_to be_able_to(:link_sample, unauthorized_study) }
    it { is_expected.not_to be_able_to(:edit, Study) }
    it { is_expected.not_to be_able_to(:edit, authorized_study) }
    it { is_expected.not_to be_able_to(:edit, unauthorized_study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.not_to be_able_to(:create, authorized_study) }
    it { is_expected.not_to be_able_to(:create, unauthorized_study) }
    it { is_expected.not_to be_able_to(:activate, Study) }
    it { is_expected.not_to be_able_to(:activate, authorized_study) }
    it { is_expected.not_to be_able_to(:activate, unauthorized_study) }
    it { is_expected.not_to be_able_to(:deactivate, Study) }
    it { is_expected.not_to be_able_to(:deactivate, authorized_study) }
    it { is_expected.not_to be_able_to(:deactivate, unauthorized_study) }
    it { is_expected.to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.not_to be_able_to(:print_asset_group_labels, authorized_study) }
    it { is_expected.not_to be_able_to(:print_asset_group_labels, unauthorized_study) }
    it { is_expected.not_to be_able_to(:accession, Study) }
    it { is_expected.not_to be_able_to(:accession, authorized_study) }
    it { is_expected.not_to be_able_to(:accession, unauthorized_study) }
    it { is_expected.not_to be_able_to(:request_additional_with, Study) }
    it { is_expected.not_to be_able_to(:request_additional_with, authorized_study) }
    it { is_expected.not_to be_able_to(:request_additional_with, unauthorized_study) }
    it { is_expected.not_to be_able_to(:grant_role, Study) }
    it { is_expected.not_to be_able_to(:grant_role, authorized_study) }
    it { is_expected.not_to be_able_to(:grant_role, unauthorized_study) }
    it { is_expected.not_to be_able_to(:remove_role, Study) }
    it { is_expected.not_to be_able_to(:remove_role, authorized_study) }
    it { is_expected.not_to be_able_to(:remove_role, unauthorized_study) }

    # Submission
    it { is_expected.to be_able_to(:create, Submission) }
    it { is_expected.to be_able_to(:read, Submission) }
    it { is_expected.not_to be_able_to(:edit, Submission) }
    it { is_expected.not_to be_able_to(:delete, Submission) }
    it { is_expected.not_to be_able_to(:change_priority, Submission) }
    it { is_expected.to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.not_to be_able_to(:create, Supplier) }
    it { is_expected.not_to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.not_to be_able_to(:create, TagGroup) }
    it { is_expected.to be_able_to(:read, TagGroup) }
    it { is_expected.not_to be_able_to(:edit, TagGroup) }
    it { is_expected.not_to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.not_to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.not_to be_able_to(:administer, User) }
    it { is_expected.to be_able_to(:edit, User) }
    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:projects, User) }
    it { is_expected.to be_able_to(:study_reports, User) }
    it { is_expected.not_to be_able_to(:create, User) }
    it { is_expected.not_to be_able_to(:delete, User) }
  end

  context 'when the user has the role "qa_manager"' do
    let(:user) { build :user, :with_role, role_name: 'qa_manager' }

    # AssetGroup
    it { is_expected.not_to be_able_to(:create, AssetGroup) }
    it { is_expected.not_to be_able_to(:edit, AssetGroup) }
    it { is_expected.not_to be_able_to(:read, AssetGroup) }
    it { is_expected.not_to be_able_to(:delete, AssetGroup) }
    it { is_expected.not_to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.not_to be_able_to(:create, BaitLibrary) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.not_to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.not_to be_able_to(:create, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:read, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.not_to be_able_to(:create, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:read, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.not_to be_able_to(:rollback, Batch) }
    it { is_expected.to be_able_to(:edit, Batch) }
    it { is_expected.to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.to be_able_to(:print, Batch) }
    it { is_expected.to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.to be_able_to(:create, Comment) }
    it { is_expected.to be_able_to(:delete, Comment) }
    it { is_expected.to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.not_to be_able_to(:create, CustomText) }
    it { is_expected.not_to be_able_to(:edit, CustomText) }
    it { is_expected.not_to be_able_to(:read, CustomText) }
    it { is_expected.not_to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.not_to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.not_to be_able_to(:create, FacultySponsor) }
    it { is_expected.not_to be_able_to(:edit, FacultySponsor) }
    it { is_expected.not_to be_able_to(:read, FacultySponsor) }
    it { is_expected.not_to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.not_to be_able_to(:create, GelsController) }
    it { is_expected.not_to be_able_to(:edit, GelsController) }
    it { is_expected.not_to be_able_to(:read, GelsController) }
    it { is_expected.not_to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.not_to be_able_to(:rename, Labware) }
    it { is_expected.not_to be_able_to(:change_purpose, Labware) }
    it { is_expected.not_to be_able_to(:edit, Labware) }
    it { is_expected.not_to be_able_to(:create, Labware) }
    it { is_expected.not_to be_able_to(:read, Labware) }
    it { is_expected.not_to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.not_to be_able_to(:create, Order) }
    it { is_expected.not_to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.not_to be_able_to(:activate, Pipeline) }
    it { is_expected.not_to be_able_to(:deactivate, Pipeline) }
    it { is_expected.not_to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.not_to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.not_to be_able_to(:create, PlatePurpose) }
    it { is_expected.not_to be_able_to(:new, PlatePurpose) }
    it { is_expected.not_to be_able_to(:edit, PlatePurpose) }
    it { is_expected.not_to be_able_to(:read, PlatePurpose) }
    it { is_expected.not_to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.not_to be_able_to(:read, PlateTemplate) }
    it { is_expected.not_to be_able_to(:create, PlateTemplate) }
    it { is_expected.not_to be_able_to(:edit, PlateTemplate) }
    it { is_expected.not_to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.not_to be_able_to(:create, PrimerPanel) }
    it { is_expected.not_to be_able_to(:edit, PrimerPanel) }
    it { is_expected.not_to be_able_to(:read, PrimerPanel) }
    it { is_expected.not_to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.not_to be_able_to(:create, Program) }
    it { is_expected.not_to be_able_to(:edit, Program) }
    it { is_expected.not_to be_able_to(:read, Program) }
    it { is_expected.not_to be_able_to(:delete, Program) }

    # Project
    it { is_expected.not_to be_able_to(:administer, Project) }
    it { is_expected.not_to be_able_to(:edit, Project) }
    it { is_expected.not_to be_able_to(:create, Project) }
    it { is_expected.to be_able_to(:create_submission, Project) }
    it { is_expected.not_to be_able_to(:read, Project) }
    it { is_expected.not_to be_able_to(:delete, Project) }

    # Purpose
    it { is_expected.not_to be_able_to(:create, Purpose) }
    it { is_expected.not_to be_able_to(:edit, Purpose) }
    it { is_expected.not_to be_able_to(:read, Purpose) }
    it { is_expected.not_to be_able_to(:delete, Purpose) }
    it { is_expected.not_to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.to be_able_to(:create, QcDecision) }
    it { is_expected.to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.not_to be_able_to(:edit, Receptacle) }
    it { is_expected.not_to be_able_to(:close, Receptacle) }
    it { is_expected.not_to be_able_to(:create, Receptacle) }
    it { is_expected.not_to be_able_to(:read, Receptacle) }
    it { is_expected.not_to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.not_to be_able_to(:create, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.to be_able_to(:read, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.not_to be_able_to(:create_additional, Request) }
    it { is_expected.not_to be_able_to(:copy, Request) }
    it { is_expected.not_to be_able_to(:cancel, Request) }
    it { is_expected.not_to be_able_to(:change_priority, Request) }
    it { is_expected.not_to be_able_to(:see_previously_failed, Request) }
    it { is_expected.not_to be_able_to(:edit_additional, Request) }
    it { is_expected.not_to be_able_to(:reset_qc_information, Request) }
    it { is_expected.not_to be_able_to(:edit, Request) }
    it { is_expected.not_to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.not_to be_able_to(:create, Robot) }
    it { is_expected.not_to be_able_to(:edit, Robot) }
    it { is_expected.to be_able_to(:read, Robot) }
    it { is_expected.not_to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.not_to be_able_to(:create, RobotProperty) }
    it { is_expected.not_to be_able_to(:edit, RobotProperty) }
    it { is_expected.not_to be_able_to(:read, RobotProperty) }
    it { is_expected.not_to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.not_to be_able_to(:create, Role) }
    it { is_expected.not_to be_able_to(:administer, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.to be_able_to(:edit, Sample) }
    it { is_expected.to be_able_to(:release, Sample) }
    it { is_expected.to be_able_to(:accession, Sample) }
    it { is_expected.not_to be_able_to(:update_released, Sample) }

    # SampleLogisticsController
    it { is_expected.not_to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.not_to be_able_to(:create, SampleManifest) }
    it { is_expected.not_to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.not_to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.not_to be_able_to(:administer, Study) }
    it { is_expected.not_to be_able_to(:unlink_sample, Study) }
    it { is_expected.not_to be_able_to(:link_sample, Study) }
    it { is_expected.not_to be_able_to(:edit, Study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.not_to be_able_to(:activate, Study) }
    it { is_expected.not_to be_able_to(:deactivate, Study) }
    it { is_expected.to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.not_to be_able_to(:accession, Study) }
    it { is_expected.not_to be_able_to(:request_additional_with, Study) }
    it { is_expected.not_to be_able_to(:grant_role, Study) }
    it { is_expected.not_to be_able_to(:remove_role, Study) }

    # Submission
    it { is_expected.to be_able_to(:create, Submission) }
    it { is_expected.to be_able_to(:read, Submission) }
    it { is_expected.not_to be_able_to(:edit, Submission) }
    it { is_expected.not_to be_able_to(:delete, Submission) }
    it { is_expected.not_to be_able_to(:change_priority, Submission) }
    it { is_expected.to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.not_to be_able_to(:create, Supplier) }
    it { is_expected.not_to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.not_to be_able_to(:create, TagGroup) }
    it { is_expected.to be_able_to(:read, TagGroup) }
    it { is_expected.not_to be_able_to(:edit, TagGroup) }
    it { is_expected.not_to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.not_to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.not_to be_able_to(:administer, User) }
    it { is_expected.to be_able_to(:edit, User) }
    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:projects, User) }
    it { is_expected.to be_able_to(:study_reports, User) }
    it { is_expected.not_to be_able_to(:create, User) }
    it { is_expected.not_to be_able_to(:delete, User) }
  end

  context 'when the user has the role "slf_gel"' do
    let(:user) { build :user, :with_role, role_name: 'slf_gel' }

    # AssetGroup
    it { is_expected.not_to be_able_to(:create, AssetGroup) }
    it { is_expected.not_to be_able_to(:edit, AssetGroup) }
    it { is_expected.not_to be_able_to(:read, AssetGroup) }
    it { is_expected.not_to be_able_to(:delete, AssetGroup) }
    it { is_expected.not_to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.not_to be_able_to(:create, BaitLibrary) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.not_to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.not_to be_able_to(:create, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:read, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.not_to be_able_to(:create, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:read, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.not_to be_able_to(:rollback, Batch) }
    it { is_expected.to be_able_to(:edit, Batch) }
    it { is_expected.to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.to be_able_to(:print, Batch) }
    it { is_expected.to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.to be_able_to(:create, Comment) }
    it { is_expected.to be_able_to(:delete, Comment) }
    it { is_expected.to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.not_to be_able_to(:create, CustomText) }
    it { is_expected.not_to be_able_to(:edit, CustomText) }
    it { is_expected.not_to be_able_to(:read, CustomText) }
    it { is_expected.not_to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.not_to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.not_to be_able_to(:create, FacultySponsor) }
    it { is_expected.not_to be_able_to(:edit, FacultySponsor) }
    it { is_expected.not_to be_able_to(:read, FacultySponsor) }
    it { is_expected.not_to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.to be_able_to(:create, GelsController) }
    it { is_expected.to be_able_to(:edit, GelsController) }
    it { is_expected.to be_able_to(:read, GelsController) }
    it { is_expected.to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.not_to be_able_to(:rename, Labware) }
    it { is_expected.not_to be_able_to(:change_purpose, Labware) }
    it { is_expected.not_to be_able_to(:edit, Labware) }
    it { is_expected.not_to be_able_to(:create, Labware) }
    it { is_expected.not_to be_able_to(:read, Labware) }
    it { is_expected.not_to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.not_to be_able_to(:create, Order) }
    it { is_expected.not_to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.not_to be_able_to(:activate, Pipeline) }
    it { is_expected.not_to be_able_to(:deactivate, Pipeline) }
    it { is_expected.not_to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.not_to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.not_to be_able_to(:create, PlatePurpose) }
    it { is_expected.not_to be_able_to(:new, PlatePurpose) }
    it { is_expected.not_to be_able_to(:edit, PlatePurpose) }
    it { is_expected.not_to be_able_to(:read, PlatePurpose) }
    it { is_expected.not_to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.not_to be_able_to(:read, PlateTemplate) }
    it { is_expected.not_to be_able_to(:create, PlateTemplate) }
    it { is_expected.not_to be_able_to(:edit, PlateTemplate) }
    it { is_expected.not_to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.not_to be_able_to(:create, PrimerPanel) }
    it { is_expected.not_to be_able_to(:edit, PrimerPanel) }
    it { is_expected.not_to be_able_to(:read, PrimerPanel) }
    it { is_expected.not_to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.not_to be_able_to(:create, Program) }
    it { is_expected.not_to be_able_to(:edit, Program) }
    it { is_expected.not_to be_able_to(:read, Program) }
    it { is_expected.not_to be_able_to(:delete, Program) }

    # Project
    it { is_expected.not_to be_able_to(:administer, Project) }
    it { is_expected.not_to be_able_to(:edit, Project) }
    it { is_expected.not_to be_able_to(:create, Project) }
    it { is_expected.to be_able_to(:create_submission, Project) }
    it { is_expected.not_to be_able_to(:read, Project) }
    it { is_expected.not_to be_able_to(:delete, Project) }

    # Purpose
    it { is_expected.not_to be_able_to(:create, Purpose) }
    it { is_expected.not_to be_able_to(:edit, Purpose) }
    it { is_expected.not_to be_able_to(:read, Purpose) }
    it { is_expected.not_to be_able_to(:delete, Purpose) }
    it { is_expected.not_to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.not_to be_able_to(:create, QcDecision) }
    it { is_expected.not_to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.not_to be_able_to(:edit, Receptacle) }
    it { is_expected.not_to be_able_to(:close, Receptacle) }
    it { is_expected.not_to be_able_to(:create, Receptacle) }
    it { is_expected.not_to be_able_to(:read, Receptacle) }
    it { is_expected.not_to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.not_to be_able_to(:create, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.to be_able_to(:read, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.not_to be_able_to(:create_additional, Request) }
    it { is_expected.not_to be_able_to(:copy, Request) }
    it { is_expected.not_to be_able_to(:cancel, Request) }
    it { is_expected.not_to be_able_to(:change_priority, Request) }
    it { is_expected.not_to be_able_to(:see_previously_failed, Request) }
    it { is_expected.not_to be_able_to(:edit_additional, Request) }
    it { is_expected.not_to be_able_to(:reset_qc_information, Request) }
    it { is_expected.not_to be_able_to(:edit, Request) }
    it { is_expected.not_to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.not_to be_able_to(:create, Robot) }
    it { is_expected.not_to be_able_to(:edit, Robot) }
    it { is_expected.to be_able_to(:read, Robot) }
    it { is_expected.not_to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.not_to be_able_to(:create, RobotProperty) }
    it { is_expected.not_to be_able_to(:edit, RobotProperty) }
    it { is_expected.not_to be_able_to(:read, RobotProperty) }
    it { is_expected.not_to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.not_to be_able_to(:create, Role) }
    it { is_expected.not_to be_able_to(:administer, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.to be_able_to(:edit, Sample) }
    it { is_expected.to be_able_to(:release, Sample) }
    it { is_expected.to be_able_to(:accession, Sample) }
    it { is_expected.not_to be_able_to(:update_released, Sample) }

    # SampleLogisticsController
    it { is_expected.to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.not_to be_able_to(:create, SampleManifest) }
    it { is_expected.not_to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.not_to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.not_to be_able_to(:administer, Study) }
    it { is_expected.not_to be_able_to(:unlink_sample, Study) }
    it { is_expected.not_to be_able_to(:link_sample, Study) }
    it { is_expected.not_to be_able_to(:edit, Study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.not_to be_able_to(:activate, Study) }
    it { is_expected.not_to be_able_to(:deactivate, Study) }
    it { is_expected.to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.not_to be_able_to(:accession, Study) }
    it { is_expected.not_to be_able_to(:request_additional_with, Study) }
    it { is_expected.not_to be_able_to(:grant_role, Study) }
    it { is_expected.not_to be_able_to(:remove_role, Study) }

    # Submission
    it { is_expected.to be_able_to(:create, Submission) }
    it { is_expected.to be_able_to(:read, Submission) }
    it { is_expected.not_to be_able_to(:edit, Submission) }
    it { is_expected.not_to be_able_to(:delete, Submission) }
    it { is_expected.not_to be_able_to(:change_priority, Submission) }
    it { is_expected.to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.not_to be_able_to(:create, Supplier) }
    it { is_expected.not_to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.not_to be_able_to(:create, TagGroup) }
    it { is_expected.to be_able_to(:read, TagGroup) }
    it { is_expected.not_to be_able_to(:edit, TagGroup) }
    it { is_expected.not_to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.not_to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.not_to be_able_to(:administer, User) }
    it { is_expected.to be_able_to(:edit, User) }
    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:projects, User) }
    it { is_expected.to be_able_to(:study_reports, User) }
    it { is_expected.not_to be_able_to(:create, User) }
    it { is_expected.not_to be_able_to(:delete, User) }
  end

  context 'when the user has the role "slf_manager"' do
    let(:user) { build :user, :with_role, role_name: 'slf_manager' }

    # AssetGroup
    it { is_expected.not_to be_able_to(:create, AssetGroup) }
    it { is_expected.not_to be_able_to(:edit, AssetGroup) }
    it { is_expected.not_to be_able_to(:read, AssetGroup) }
    it { is_expected.not_to be_able_to(:delete, AssetGroup) }
    it { is_expected.not_to be_able_to(:new, AssetGroup) }

    # BaitLibrary
    it { is_expected.not_to be_able_to(:create, BaitLibrary) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary) }

    # BaitLibrary::Supplier
    it { is_expected.not_to be_able_to(:create, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:edit, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:read, BaitLibrary::Supplier) }
    it { is_expected.not_to be_able_to(:delete, BaitLibrary::Supplier) }

    # BaitLibraryType
    it { is_expected.not_to be_able_to(:create, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:edit, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:read, BaitLibraryType) }
    it { is_expected.not_to be_able_to(:delete, BaitLibraryType) }

    # BarcodePrinter
    it { is_expected.not_to be_able_to(:create, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:edit, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:read, BarcodePrinter) }
    it { is_expected.not_to be_able_to(:delete, BarcodePrinter) }

    # Batch
    it { is_expected.not_to be_able_to(:rollback, Batch) }
    it { is_expected.to be_able_to(:edit, Batch) }
    it { is_expected.to be_able_to(:create_stock_asset, Batch) }
    it { is_expected.to be_able_to(:sample_prep_worksheet, Batch) }
    it { is_expected.to be_able_to(:print, Batch) }
    it { is_expected.to be_able_to(:verify, Batch) }

    # Comment
    it { is_expected.to be_able_to(:create, Comment) }
    it { is_expected.to be_able_to(:delete, Comment) }
    it { is_expected.to be_able_to(:new, Comment) }

    # CustomText
    it { is_expected.not_to be_able_to(:create, CustomText) }
    it { is_expected.not_to be_able_to(:edit, CustomText) }
    it { is_expected.not_to be_able_to(:read, CustomText) }
    it { is_expected.not_to be_able_to(:delete, CustomText) }

    # Delayed::Backend::ActiveRecord::Job
    it { is_expected.to be_able_to(:read, Delayed::Backend::ActiveRecord::Job) }

    # Delayed::Job
    it { is_expected.to be_able_to(:read, Delayed::Job) }

    # Document
    it { is_expected.not_to be_able_to(:delete, Document) }

    # FacultySponsor
    it { is_expected.not_to be_able_to(:create, FacultySponsor) }
    it { is_expected.not_to be_able_to(:edit, FacultySponsor) }
    it { is_expected.not_to be_able_to(:read, FacultySponsor) }
    it { is_expected.not_to be_able_to(:delete, FacultySponsor) }

    # GelsController
    it { is_expected.to be_able_to(:create, GelsController) }
    it { is_expected.to be_able_to(:edit, GelsController) }
    it { is_expected.to be_able_to(:read, GelsController) }
    it { is_expected.to be_able_to(:delete, GelsController) }

    # Labware
    it { is_expected.not_to be_able_to(:rename, Labware) }
    it { is_expected.not_to be_able_to(:change_purpose, Labware) }
    it { is_expected.not_to be_able_to(:edit, Labware) }
    it { is_expected.not_to be_able_to(:create, Labware) }
    it { is_expected.not_to be_able_to(:read, Labware) }
    it { is_expected.not_to be_able_to(:delete, Labware) }

    # Order
    it { is_expected.not_to be_able_to(:create, Order) }
    it { is_expected.not_to be_able_to(:new, Order) }

    # Pipeline
    it { is_expected.not_to be_able_to(:activate, Pipeline) }
    it { is_expected.not_to be_able_to(:deactivate, Pipeline) }
    it { is_expected.not_to be_able_to(:update_priority, Pipeline) }

    # Plate
    it { is_expected.to be_able_to(:convert_to_tube, Plate) }

    # PlatePurpose
    it { is_expected.not_to be_able_to(:create, PlatePurpose) }
    it { is_expected.not_to be_able_to(:new, PlatePurpose) }
    it { is_expected.not_to be_able_to(:edit, PlatePurpose) }
    it { is_expected.not_to be_able_to(:read, PlatePurpose) }
    it { is_expected.not_to be_able_to(:delete, PlatePurpose) }

    # PlateTemplate
    it { is_expected.to be_able_to(:read, PlateTemplate) }
    it { is_expected.to be_able_to(:create, PlateTemplate) }
    it { is_expected.to be_able_to(:edit, PlateTemplate) }
    it { is_expected.to be_able_to(:delete, PlateTemplate) }

    # PrimerPanel
    it { is_expected.not_to be_able_to(:create, PrimerPanel) }
    it { is_expected.not_to be_able_to(:edit, PrimerPanel) }
    it { is_expected.not_to be_able_to(:read, PrimerPanel) }
    it { is_expected.not_to be_able_to(:delete, PrimerPanel) }

    # Program
    it { is_expected.not_to be_able_to(:create, Program) }
    it { is_expected.not_to be_able_to(:edit, Program) }
    it { is_expected.not_to be_able_to(:read, Program) }
    it { is_expected.not_to be_able_to(:delete, Program) }

    # Project
    it { is_expected.not_to be_able_to(:administer, Project) }
    it { is_expected.not_to be_able_to(:edit, Project) }
    it { is_expected.not_to be_able_to(:create, Project) }
    it { is_expected.to be_able_to(:create_submission, Project) }
    it { is_expected.not_to be_able_to(:read, Project) }
    it { is_expected.not_to be_able_to(:delete, Project) }

    # Purpose
    it { is_expected.not_to be_able_to(:create, Purpose) }
    it { is_expected.not_to be_able_to(:edit, Purpose) }
    it { is_expected.not_to be_able_to(:read, Purpose) }
    it { is_expected.not_to be_able_to(:delete, Purpose) }
    it { is_expected.not_to be_able_to(:new, Purpose) }

    # QcDecision
    it { is_expected.not_to be_able_to(:create, QcDecision) }
    it { is_expected.not_to be_able_to(:new, QcDecision) }

    # Receptacle
    it { is_expected.not_to be_able_to(:edit, Receptacle) }
    it { is_expected.not_to be_able_to(:close, Receptacle) }
    it { is_expected.not_to be_able_to(:create, Receptacle) }
    it { is_expected.not_to be_able_to(:read, Receptacle) }
    it { is_expected.not_to be_able_to(:delete, Receptacle) }

    # ReferenceGenome
    it { is_expected.not_to be_able_to(:create, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:edit, ReferenceGenome) }
    it { is_expected.to be_able_to(:read, ReferenceGenome) }
    it { is_expected.not_to be_able_to(:delete, ReferenceGenome) }

    # Request
    it { is_expected.not_to be_able_to(:create_additional, Request) }
    it { is_expected.not_to be_able_to(:copy, Request) }
    it { is_expected.not_to be_able_to(:cancel, Request) }
    it { is_expected.not_to be_able_to(:change_priority, Request) }
    it { is_expected.not_to be_able_to(:see_previously_failed, Request) }
    it { is_expected.not_to be_able_to(:edit_additional, Request) }
    it { is_expected.not_to be_able_to(:reset_qc_information, Request) }
    it { is_expected.not_to be_able_to(:edit, Request) }
    it { is_expected.not_to be_able_to(:change_decision, Request) }

    # Robot
    it { is_expected.not_to be_able_to(:create, Robot) }
    it { is_expected.not_to be_able_to(:edit, Robot) }
    it { is_expected.to be_able_to(:read, Robot) }
    it { is_expected.not_to be_able_to(:delete, Robot) }

    # RobotProperty
    it { is_expected.not_to be_able_to(:create, RobotProperty) }
    it { is_expected.not_to be_able_to(:edit, RobotProperty) }
    it { is_expected.not_to be_able_to(:read, RobotProperty) }
    it { is_expected.not_to be_able_to(:delete, RobotProperty) }

    # Role
    it { is_expected.not_to be_able_to(:create, Role) }
    it { is_expected.not_to be_able_to(:administer, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:delete, Role) }

    # Sample
    it { is_expected.to be_able_to(:edit, Sample) }
    it { is_expected.to be_able_to(:release, Sample) }
    it { is_expected.to be_able_to(:accession, Sample) }
    it { is_expected.not_to be_able_to(:update_released, Sample) }

    # SampleLogisticsController
    it { is_expected.to be_able_to(:read, SampleLogisticsController) }

    # SampleManifest
    it { is_expected.to be_able_to(:create, SampleManifest) }
    it { is_expected.to be_able_to(:new, SampleManifest) }

    # Sequencescape
    it { is_expected.not_to be_able_to(:administer, Sequencescape) }

    # Study
    it { is_expected.not_to be_able_to(:administer, Study) }
    it { is_expected.not_to be_able_to(:unlink_sample, Study) }
    it { is_expected.not_to be_able_to(:link_sample, Study) }
    it { is_expected.not_to be_able_to(:edit, Study) }
    it { is_expected.not_to be_able_to(:create, Study) }
    it { is_expected.not_to be_able_to(:activate, Study) }
    it { is_expected.not_to be_able_to(:deactivate, Study) }
    it { is_expected.to be_able_to(:print_asset_group_labels, Study) }
    it { is_expected.not_to be_able_to(:accession, Study) }
    it { is_expected.not_to be_able_to(:request_additional_with, Study) }
    it { is_expected.not_to be_able_to(:grant_role, Study) }
    it { is_expected.not_to be_able_to(:remove_role, Study) }

    # Submission
    it { is_expected.to be_able_to(:create, Submission) }
    it { is_expected.to be_able_to(:read, Submission) }
    it { is_expected.not_to be_able_to(:edit, Submission) }
    it { is_expected.not_to be_able_to(:delete, Submission) }
    it { is_expected.not_to be_able_to(:change_priority, Submission) }
    it { is_expected.to be_able_to(:new, Submission) }

    # Supplier
    it { is_expected.to be_able_to(:create, Supplier) }
    it { is_expected.to be_able_to(:new, Supplier) }

    # TagGroup
    it { is_expected.not_to be_able_to(:create, TagGroup) }
    it { is_expected.to be_able_to(:read, TagGroup) }
    it { is_expected.not_to be_able_to(:edit, TagGroup) }
    it { is_expected.not_to be_able_to(:delete, TagGroup) }

    # TagLayoutTemplate
    it { is_expected.not_to be_able_to(:create, TagLayoutTemplate) }
    it { is_expected.to be_able_to(:read, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:edit, TagLayoutTemplate) }
    it { is_expected.not_to be_able_to(:delete, TagLayoutTemplate) }

    # User
    it { is_expected.not_to be_able_to(:administer, User) }
    it { is_expected.to be_able_to(:edit, User) }
    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:projects, User) }
    it { is_expected.to be_able_to(:study_reports, User) }
    it { is_expected.not_to be_able_to(:create, User) }
    it { is_expected.not_to be_able_to(:delete, User) }
  end
end
# rubocop:enable RSpec/AggregateExamples
