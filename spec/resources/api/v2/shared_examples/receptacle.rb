# frozen_string_literal: true

shared_examples 'a receptacle resource' do
  # Attributes
  it { is_expected.to have_readwrite_attribute :coverage }
  it { is_expected.to have_readwrite_attribute :diluent_volume }
  it { is_expected.to have_write_once_attribute :name }
  it { is_expected.to have_readwrite_attribute :pcr_cycles }
  it { is_expected.to have_readonly_attribute :state }
  it { is_expected.to have_readwrite_attribute :sub_pool }
  it { is_expected.to have_readwrite_attribute :submit_for_sequencing }
  it { is_expected.to have_readonly_attribute :uuid }

  # Relationships
  it { is_expected.to have_a_readonly_has_many(:samples).with_class_name('Sample') }
  it { is_expected.to have_a_write_once_has_many(:studies).with_class_name('Study') }
  it { is_expected.to have_a_write_once_has_many(:projects).with_class_name('Project') }

  it { is_expected.to have_a_readonly_has_many(:requests_as_source).with_class_name('Request') }
  it { is_expected.to have_a_readonly_has_many(:requests_as_target).with_class_name('Request') }
  it { is_expected.to have_a_readonly_has_many(:qc_results).with_class_name('QcResult') }
  it { is_expected.to have_a_readonly_has_many(:aliquots).with_class_name('Aliquot') }

  it { is_expected.to have_a_readonly_has_many(:downstream_assets) } # polymorphic
  it { is_expected.to have_a_readonly_has_many(:downstream_wells).with_class_name('Well') }
  it { is_expected.to have_a_readonly_has_many(:downstream_plates).with_class_name('Plate') }
  it { is_expected.to have_a_readonly_has_many(:downstream_tubes).with_class_name('Tube') }

  it { is_expected.to have_a_readonly_has_many(:upstream_assets) } # polymorphic
  it { is_expected.to have_a_readonly_has_many(:upstream_wells).with_class_name('Well') }
  it { is_expected.to have_a_readonly_has_many(:upstream_plates).with_class_name('Plate') }
  it { is_expected.to have_a_readonly_has_many(:upstream_tubes).with_class_name('Tube') }

  it { is_expected.to have_a_write_once_has_one(:labware).with_class_name('Labware') }

  # Filters
  it { is_expected.to filter(:uuid) }
end
