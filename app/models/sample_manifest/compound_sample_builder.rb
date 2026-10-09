# frozen_string_literal: true

# Creates, or updates, the compound sample for one receptacle of a compound
# sample manifest, e.g. a tube of a Kinnex compound sample tube manifest.
#
# The manifest upload creates the component samples without aliquots. This
# creates:
# - the compound sample, in the study, named with a new sanger sample id
# - a link to each component sample, with the component's tag
# - the compound sample's aliquot: the only aliquot in the receptacle
#
# A re-upload updates the compound sample like other manifests update their
# samples: it adds new component samples, corrects tags and updates the
# shared metadata. It does not remove component samples.
#
# The component samples are told apart by their tags, so a tag can be used
# only once in a compound sample.
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
  # @raise [ActiveRecord::RecordInvalid] if a tag is used more than once
  def build!
    ActiveRecord::Base.transaction do
      create_compound_sample.tap do |compound|
        link_components(compound)
        check_tags_unique!(compound)
        create_aliquot(compound)
      end
    end
  end

  # Links the given component samples that are new to the compound sample,
  # corrects the tags of the others, and updates the shared metadata from
  # all its component samples.
  # @param compound [Sample] the compound sample
  # @return [Boolean] true
  # @raise [ActiveRecord::RecordInvalid] if a tag is used more than once
  def update!(compound)
    ActiveRecord::Base.transaction do
      update_links(compound)
      check_tags_unique!(compound)
      all_components = compound.component_samples.reload
      compound.sample_metadata.update!(shared_metadata(all_components))
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

  def update_links(compound)
    links = compound.joins_as_compound_sample.index_by(&:component_sample_id)
    tags_by_component.each do |component, tag|
      link = links[component.id]
      next link.update!(tag:) if link

      compound.joins_as_compound_sample.create!(
        component_sample: component,
        tag: tag
      )
    end
  end

  # Checks the tags the compound sample ends up with, after all the links
  # are made. So two component samples can swap their tags, and a tag kept
  # without an override, or by a cleared row, is still checked.
  def check_tags_unique!(compound)
    links = compound.joins_as_compound_sample.includes(:component_sample)
    shared = links.select(&:tag_id).group_by(&:tag_id).values.select(&:many?)
    return if shared.empty?

    shared.each do |shared_links|
      names = shared_links.map { |link| link.component_sample.name }
      compound.errors.add(:base, "Component samples #{names.to_sentence} " \
                                 'have the same component tag sequence')
    end
    raise ActiveRecord::RecordInvalid, compound
  end

  def create_aliquot(compound)
    receptacle.aliquots.create!(
      sample: compound,
      study: study,
      library_type: library_type
    )
  end

  # Each field's value when all the components share it, otherwise nil.
  def shared_metadata(components = tags_by_component.keys)
    SHARED_METADATA.index_with do |field|
      values = components.map { |c| c.sample_metadata.public_send(field) }
      values.first if values.uniq.one?
    end
  end
end
