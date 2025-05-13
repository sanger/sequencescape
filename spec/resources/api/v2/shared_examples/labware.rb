# frozen_string_literal: true

shared_examples 'a labware resource' do
  # Attributes
  it { is_expected.to have_readonly_attribute :uuid }
  it { is_expected.to have_readonly_attribute :name }
  it { is_expected.to have_readonly_attribute :labware_barcode }
  it { is_expected.to have_readonly_attribute :state }
  it { is_expected.to have_readonly_attribute :created_at }
  it { is_expected.to have_readonly_attribute :updated_at }
  it { is_expected.to have_readonly_attribute :retention_instruction }

  # Relationships
  it { is_expected.to have_a_write_once_has_one(:purpose).with_class_name('Purpose') }

  it do
    is_expected.to have_a_writable_has_one(:custom_metadatum_collection).with_class_name('CustomMetadatumCollection')
  end

  it { is_expected.to have_a_write_once_has_many(:samples).with_class_name('Sample') }
  it { is_expected.to have_a_write_once_has_many(:studies).with_class_name('Study') }
  it { is_expected.to have_a_write_once_has_many(:projects).with_class_name('Project') }
  it { is_expected.to have_a_readonly_has_many(:comments).with_class_name('Comment') }
  it { is_expected.to have_a_readonly_has_many(:qc_files).with_class_name('QcFile') }

  # If we're using the labware endpoint, we need the generic receptacles
  # association if we are to eager load the contents of returned labware
  it { is_expected.to have_a_readonly_has_many(:receptacles) }

  it { is_expected.to have_a_readonly_has_many(:ancestors) }
  it { is_expected.to have_a_readonly_has_many(:descendants) }
  it { is_expected.to have_a_readonly_has_many(:parents) }
  it { is_expected.to have_a_readonly_has_many(:children) }
  it { is_expected.to have_a_readonly_has_many(:child_plates).with_class_name('Plate') }
  it { is_expected.to have_a_readonly_has_many(:child_tubes).with_class_name('Tube') }
  it { is_expected.to have_a_readonly_has_many(:direct_submissions).with_class_name('Submission') }
  it { is_expected.to have_a_readonly_has_many(:state_changes).with_class_name('StateChange') }

  # Filters
  it { is_expected.to filter(:barcode) }
  it { is_expected.to filter(:uuid) }
  it { is_expected.to filter(:purpose_name) }
  it { is_expected.to filter(:purpose_id) }
  it { is_expected.to filter(:without_children) }
  it { is_expected.to filter(:created_at_gt) }
  it { is_expected.to filter(:updated_at_gt) }
  it { is_expected.to filter(:include_used) }
end
