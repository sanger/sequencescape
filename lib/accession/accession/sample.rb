module Accession
  class Sample

    # Validate the sample to ensure that it can be accessioned
    # The sample must:
    # - not be accessioned
    # - have at least one associated open or managed study that has been accessioned
    # - must not have an open and managed study that have been accessioned
    # - must have the required fields filled in based on the associated study
    # - if the sample has an open study then sample_taxon_id and sample_common_name must be completed
    # - if the sample has a managed study then gender, phenotype, donor_id must be completed
    # If the sample meets all of the above requirements it can be accessioned
    # If the sample has an open study it will be sent to the ENA
    # If the sample has a managed study it will be sent to the EGA

    include ActiveModel::Validations

    STUDY_TYPES = {
      "open" => {service: :ENA, required_fields: [:sample_taxon_id, :sample_common_name]},
      "managed" => {service: :EGA, required_fields: [:sample_taxon_id, :sample_common_name, :gender, :phenotype, :donor_id]}
    }

    ARRAY_EXPRESS_FIELDS = [:genotype, :phenotype, :strain_or_line, :developmental_stage, 
                            :sex, :cell_type, :disease_state, :compound, :dose, :immunoprecipitate,
                            :growth_condition, :rnai, :organism_part, :species, :time_point, :age, :treatment]

    attr_reader :sample, :studies, :service, :required_fields

    validate :check_sample, :check_studies, :check_required_fields

    def initialize(sample)
      @sample = sample
      @studies = set_studies
      set_study_type
    end

    def name
      @name ||= (sample.sample_metadata.sample_public_name  || sample.name).downcase.gsub(/[^\w\d]/i,'_')
    end

    def common_name
      sample.sample_metadata.sample_common_name
    end

    def taxon_id
      sample.sample_metadata.sample_taxon_id
    end

  private

    def set_studies
      sample.studies
            .for_sample_accessioning
            .group_by { |study| study.study_metadata.data_release_strategy }
    end

    def set_study_type
      if (studies.length == 1)
        study_type = STUDY_TYPES.fetch(studies.keys.first)
        if study_type.present?
          @service, @required_fields = study_type[:service], study_type[:required_fields]
        end
      end
    end

    def check_sample
      if sample.sample_metadata.sample_ebi_accession_number.present?
        errors.add(:sample, "has already been accessioned")
      end
    end

    def check_required_fields
      if required_fields.present?
        required_fields.each do |required_field|
          unless sample.sample_metadata.send(required_field).present?
            errors.add(:sample, "required field is missing")
          end
        end
      end
    end

    def check_studies
      if service.nil?
        errors.add(:sample, "no appropriate studies")
      end

    end

  end
end