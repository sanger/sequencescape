# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

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

        scope :including_associations_for_json, -> { includes([:uuid_object, { sample_metadata: :reference_genome }, { studies: [:study_metadata, :uuid_object] }]) }
        alias_method(:json_root, :url_name)
      end
    end

    def url_name
      'sample'
    end
  end

  renders_model(::Sample)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:consent_withdrawn)
  map_attribute_to_json_attribute(:new_name_format)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:sanger_sample_id)
  map_attribute_to_json_attribute(:control)
  map_attribute_to_json_attribute(:sample_manifest_id)
  map_attribute_to_json_attribute(:empty_supplier_sample_name)
  map_attribute_to_json_attribute(:updated_by_manifest)

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
    with_association(:reference_genome, lookup_by: :name) do
      map_attribute_to_json_attribute(:name, 'reference_genome')
    end
    map_attribute_to_json_attribute(:supplier_name)
    map_attribute_to_json_attribute(:donor_id)
  end

  self.related_resources = [:sample_tubes]

  extra_json_attributes do |_object, json_attributes|
    if json_attributes['reference_genome'].blank?
      json_attributes['reference_genome'] = nil
    end
  end

  # Whenever we create samples through the API we also need to register a sample tube too.  The user
  # can then retrieve the sample tube information through the API.
  def self.create!(parameters)
    super.tap do |sample|
      Tube::Purpose.standard_sample_tube.create!.aliquots.create!(sample: sample)
    end
  end
end
