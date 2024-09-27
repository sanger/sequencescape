# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {Sample}
# Historically used to be v0.5 API
class Api::SampleIo < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::SampleIo
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json,
              lambda {
                includes(
                  [:uuid_object, { sample_metadata: :reference_genome }, { studies: %i[study_metadata uuid_object] }]
                )
              }
      end
    end

    def json_root
      'sample'
    end
  end

  renders_model(::Sample)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:new_name_format)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:sanger_sample_id)
  map_attribute_to_json_attribute(:control)
  map_attribute_to_json_attribute(:control_type)
  map_attribute_to_json_attribute(:sample_manifest_id)
  map_attribute_to_json_attribute(:empty_supplier_sample_name)
  map_attribute_to_json_attribute(:updated_by_manifest)
  map_attribute_to_json_attribute(:consent_withdrawn)

  with_nested_has_many_association(:component_samples, as: :component_sample_uuids) do
    map_attribute_to_json_attribute(:uuid)
  end

  with_association(:sample_metadata) do
    map_attribute_to_json_attribute(:organism)
    map_attribute_to_json_attribute(:cohort)
    map_attribute_to_json_attribute(:country_of_origin)
    map_attribute_to_json_attribute(:geographical_region)
    map_attribute_to_json_attribute(:ethnicity)
    map_attribute_to_json_attribute(:volume, 'customer_measured_volume')
    map_attribute_to_json_attribute(:mother)
    map_attribute_to_json_attribute(:father)
    map_attribute_to_json_attribute(:replicate)
    map_attribute_to_json_attribute(:gc_content)
    map_attribute_to_json_attribute(:gender)
    map_attribute_to_json_attribute(:dna_source)
    map_attribute_to_json_attribute(:sample_public_name, 'public_name')
    map_attribute_to_json_attribute(:sample_common_name, 'common_name')
    map_attribute_to_json_attribute(:sample_strain_att, 'strain')
    map_attribute_to_json_attribute(:sample_taxon_id, 'taxon_id')
    map_attribute_to_json_attribute(:sample_ebi_accession_number, 'accession_number')
    map_attribute_to_json_attribute(:sample_description, 'description')
    map_attribute_to_json_attribute(:sample_sra_hold, 'sample_visibility')
    map_attribute_to_json_attribute(:developmental_stage)
    with_association(:reference_genome, lookup_by: :name) { map_attribute_to_json_attribute(:name, 'reference_genome') }
    map_attribute_to_json_attribute(:supplier_name)
    map_attribute_to_json_attribute(:donor_id)
    map_attribute_to_json_attribute(:phenotype)
    map_attribute_to_json_attribute(:sibling)
    map_attribute_to_json_attribute(:is_resubmitted)
    map_attribute_to_json_attribute(:date_of_sample_collection)
    map_attribute_to_json_attribute(:date_of_sample_extraction)
    map_attribute_to_json_attribute(:sample_extraction_method, 'extraction_method')
    map_attribute_to_json_attribute(:sample_purified, 'purified')
    map_attribute_to_json_attribute(:purification_method)
    map_attribute_to_json_attribute(:concentration, 'customer_measured_concentration')
    map_attribute_to_json_attribute(:concentration_determined_by)
    map_attribute_to_json_attribute(:sample_type)
    map_attribute_to_json_attribute(:sample_storage_conditions, 'storage_conditions')
    map_attribute_to_json_attribute(:genotype)
    map_attribute_to_json_attribute(:age)
    map_attribute_to_json_attribute(:cell_type)
    map_attribute_to_json_attribute(:disease_state)
    map_attribute_to_json_attribute(:compound)
    map_attribute_to_json_attribute(:dose)
    map_attribute_to_json_attribute(:immunoprecipitate)
    map_attribute_to_json_attribute(:growth_condition)
    map_attribute_to_json_attribute(:organism_part)
    map_attribute_to_json_attribute(:time_point)
    map_attribute_to_json_attribute(:disease)
    map_attribute_to_json_attribute(:subject)
    map_attribute_to_json_attribute(:treatment)
    map_attribute_to_json_attribute(:date_of_consent_withdrawn)
    map_attribute_to_json_attribute(:user_id_of_consent_withdrawn, 'marked_as_consent_withdrawn_by')
  end

  extra_json_attributes do |_object, json_attributes|
    json_attributes['reference_genome'] = nil if json_attributes['reference_genome'].blank?

    user_id = json_attributes['marked_as_consent_withdrawn_by']
    json_attributes['marked_as_consent_withdrawn_by'] = User.find_by(id: user_id)&.login if user_id.present?
  end

  # Whenever we create samples through the API we also need to register a sample tube too.  The user
  # can then retrieve the sample tube information through the API.
  def self.create!(parameters)
    super.tap { |sample| Tube::Purpose.standard_sample_tube.create!.aliquots.create!(sample:) }
  end
end
