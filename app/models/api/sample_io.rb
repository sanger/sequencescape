# Despite name controls rendering of warehouse messages for {Sample}
# Historically used to be v0.5 API
class Api::SampleIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::SampleIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([:uuid_object, { sample_metadata: :reference_genome }, { studies: %i[study_metadata uuid_object] }]) }
      end
    end

    def json_root
      'sample'
    end
  end

  # Sequencescape field 'control' was changed to an enum May 2020
  # MLWH field retained as a boolean
  # because difficult to change the legacy warehouse which receives same message
  # map all types of control to 1
  CONTROL_DATA_MAPPING = {
    'not_control' => '0',
    'control' => '1',
    'positive_control' => '1',
    'negative_control' => '1'
  }.freeze

  renders_model(::Sample)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:new_name_format)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:sanger_sample_id)
  map_attribute_to_json_attribute(:control)
  map_attribute_to_json_attribute(:sample_manifest_id)
  map_attribute_to_json_attribute(:empty_supplier_sample_name)
  map_attribute_to_json_attribute(:updated_by_manifest)
  map_attribute_to_json_attribute(:consent_withdrawn)

  with_association(:sample_metadata) do
    map_attribute_to_json_attribute(:organism)
    map_attribute_to_json_attribute(:cohort)
    map_attribute_to_json_attribute(:country_of_origin)
    map_attribute_to_json_attribute(:geographical_region)
    map_attribute_to_json_attribute(:ethnicity)
    map_attribute_to_json_attribute(:volume)
    map_attribute_to_json_attribute(:supplier_plate_id)
    map_attribute_to_json_attribute(:mother)
    map_attribute_to_json_attribute(:father)
    map_attribute_to_json_attribute(:replicate)
    map_attribute_to_json_attribute(:gc_content)
    map_attribute_to_json_attribute(:gender)
    map_attribute_to_json_attribute(:dna_source)
    map_attribute_to_json_attribute(:sample_public_name)
    map_attribute_to_json_attribute(:sample_common_name)
    map_attribute_to_json_attribute(:sample_strain_att)
    map_attribute_to_json_attribute(:sample_taxon_id)
    map_attribute_to_json_attribute(:sample_ebi_accession_number)
    map_attribute_to_json_attribute(:sample_description)
    map_attribute_to_json_attribute(:sample_sra_hold)
    map_attribute_to_json_attribute(:developmental_stage)
    with_association(:reference_genome, lookup_by: :name) do
      map_attribute_to_json_attribute(:name, 'reference_genome')
    end
    map_attribute_to_json_attribute(:supplier_name)
    map_attribute_to_json_attribute(:donor_id)
  end

  extra_json_attributes do |_object, json_attributes|
    if json_attributes['reference_genome'].blank?
      json_attributes['reference_genome'] = nil
    end
    json_attributes['control'] = CONTROL_DATA_MAPPING[json_attributes['control']] # sets to nil if not found in hash
  end

  # Whenever we create samples through the API we also need to register a sample tube too.  The user
  # can then retrieve the sample tube information through the API.
  def self.create!(parameters)
    super.tap do |sample|
      Tube::Purpose.standard_sample_tube.create!.aliquots.create!(sample: sample)
    end
  end
end
