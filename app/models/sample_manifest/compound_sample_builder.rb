# frozen_string_literal: true

# Creates the compound sample for one receptacle of a compound sample
# manifest, e.g. a tube of a Kinnex compound sample tube manifest.
#
# The manifest upload creates the component samples without aliquots. This
# creates:
# - the compound sample, in the study, named with a new sanger sample id
# - a link to each component sample, with the component's tag
# - the compound sample's aliquot: the only aliquot in the receptacle
class SampleManifest::CompoundSampleBuilder
  # Metadata copied to the compound sample when all its components agree.
  SHARED_METADATA = %i[supplier_name sample_common_name sample_taxon_id].freeze

  # @param study [Study] the study of the manifest
  # @param receptacle [Receptacle] the receptacle for the compound sample
  # @param tags_by_component [Hash{Sample => Tag}] the component samples and
  #   their tags
  # @param library_type [String, nil] the library type of the aliquot
  def initialize(study:, receptacle:, tags_by_component:, library_type: nil)
    @study = study
    @receptacle = receptacle
    @tags_by_component = tags_by_component
    @library_type = library_type
  end

  # @return [Sample] the compound sample
  def build!
    ActiveRecord::Base.transaction do
      create_compound_sample.tap do |compound|
        link_components(compound)
        create_aliquot(compound)
      end
    end
  end

  private

  attr_reader :study, :receptacle, :tags_by_component, :library_type

  def create_compound_sample
    study.samples.create!(
      name: SangerSampleId.generate_sanger_sample_id!(study.abbreviation),
      sample_metadata_attributes: shared_metadata
    )
  end

  def link_components(compound)
    tags_by_component.each do |component, tag|
      compound.joins_as_compound_sample.create!(
        component_sample: component,
        tag: tag
      )
    end
  end

  def create_aliquot(compound)
    receptacle.aliquots.create!(
      sample: compound,
      study: study,
      library_type: library_type
    )
  end

  def shared_metadata
    SHARED_METADATA.each_with_object({}) do |field, shared|
      values = components.map { |c| c.sample_metadata.public_send(field) }
      shared[field] = values.first if values.uniq.one? && values.first.present?
    end
  end

  def components
    tags_by_component.keys
  end
end
