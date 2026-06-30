# frozen_string_literal: true

module Api
  module V2
    module Sapio
      class StudyMetadataResource < Api::V2::StudyMetadataResource
        # @!attribute [r] old_sac_sponsor
        #   @return [String, nil] Legacy SAC sponsor value.
        #   @example Jane Doe
        attribute :old_sac_sponsor

        # @!attribute [r] study_description
        #   @return [String, nil] Study description.
        attribute :study_description

        # @!attribute [r] contaminated_human_dna
        #   @return [String, nil] Does this study contain samples that are
        #     contaminated with human DNA which must be removed prior to
        #     analysis? (Yes or No)
        attribute :contaminated_human_dna

        # @!attribute [r] study_project_id
        #   @return [String, nil] ENA Project ID.
        #   @note '0' if not known.
        attribute :study_project_id

        # @!attribute [r] study_abstract
        #   @return [String, nil] Abstract.
        attribute :study_abstract

        # @!attribute [r] study_study_title
        #   @return [String, nil] Title.
        attribute :study_study_title

        # @!attribute [r] study_ebi_accession_number
        #   @return [String, nil] ENA Study Accession Number.
        #   @example 'ERP123456'
        attribute :study_ebi_accession_number

        # @!attribute [r] study_sra_hold
        #   @return [String, nil] Study Visibility. (Hold or Public)
        attribute :study_sra_hold

        # @!attribute [r] contains_human_dna
        #   @return [String, nil] Do any of the samples in this study contain
        #     human DNA? (Yes or No)
        attribute :contains_human_dna

        # @!attribute [r] study_name_abbreviation
        #   @return [String, nil] Study name abbreviation.
        #   @example 'ABC_DEF'
        attribute :study_name_abbreviation

        # @!attribute [r] reference_genome_old
        #   @return [String, nil] Legacy reference genome value.
        #   @note Last used in 2012
        attribute :reference_genome_old

        # @!attribute [r] data_release_strategy
        #   @return [String, nil] What is the data release strategy for this
        #      study? (open, managed, or 'not applicable')
        attribute :data_release_strategy

        # @!attribute [r] data_release_standard_agreement
        #   @return [String, nil] Will you be using WTSI's standard access
        #   agreement? (Yes or No)
        attribute :data_release_standard_agreement

        # @!attribute [r] data_release_timing
        #   @return [String, nil] How is the data release to be timed?
        #     (standard, immediate, delayed, never, or 'delay until publication')
        attribute :data_release_timing

        # @!attribute [r] data_release_delay_reason
        #   @return [String, nil] Reason for delaying release.
        #   @example 'PhD Study'
        attribute :data_release_delay_reason

        # @!attribute [r] data_release_delay_other_comment
        #   @return [String, nil] Please explain the reason for delaying release.
        #   @example 'Sensitive studies - the cohort in this project includes
        #     individuals of some known ancestry.'
        attribute :data_release_delay_other_comment

        # @!attribute [r] data_release_delay_period
        #   @return [String, nil] Delay for.
        #   @example '18 months'
        attribute :data_release_delay_period

        # @!attribute [r] data_release_delay_approval
        #   @return [String, nil] Has the delay period been approved by the
        #     data sharing committee for this project? (Yes or No)
        attribute :data_release_delay_approval

        # @!attribute [r] data_release_delay_reason_comment
        #   @return [String, nil] Comment regarding data release timing and approval.
        #   @example 'Long-term study requiring delayed data-release - request to DAC pending'
        attribute :data_release_delay_reason_comment

        # @!attribute [r] data_release_prevention_reason
        #   @return [String, nil] What is the reason for preventing data release?
        #   @example 'Pilot or validation studies - DAC approval not required'
        attribute :data_release_prevention_reason

        # @!attribute [r] data_release_prevention_approval
        #   @return [String, nil] If reason for exemption requires DAC approval,
        #     what is the approval number?
        #   @note Mixed strings, and Yes or No values are present in the database.
        attribute :data_release_prevention_approval

        # @!attribute [r] data_release_prevention_reason_comment
        #   @return [String, nil] Comment regarding prevention of data release and approval.
        #   @example 'Pilot work for Element Aviti platform'
        attribute :data_release_prevention_reason_comment

        # @!attribute [r] snp_study_id
        #   @return [Integer, nil] SNP study ID.
        #   @note Last used in 2012
        attribute :snp_study_id

        # @!attribute [r] snp_parent_study_id
        #   @return [Integer, nil] SNP parent study ID.
        #   @note Last used in 2012
        attribute :snp_parent_study_id

        # @!attribute [r] bam
        #   @return [Boolean, nil] Alignments in BAM.
        attribute :bam

        # @!attribute [r] study_type
        #   @return [StudyTypeResource, nil] The study type associated with this
        #     study metadata.
        has_one :study_type, class_name: 'StudyType', foreign_key_on: :self

        # @!attribute [r] study_type_id
        #   @return [Integer, nil] Study Type.
        #   @note Exposing it as an attribute is for convenience.
        attribute :study_type_id

        # @!attribute [r] study_type_name
        #   @return [String, nil] Study Type name
        #   @note Exposing it as an attribute is for convenience.
        #   @example 'Whole Genome Sequencing'
        attribute :study_type_name

        # @!attribute [r] data_release_study_type
        #   @return [DataReleaseStudyTypeResource, nil] The data release study
        #     type associated with this study metadata.
        has_one :data_release_study_type, class_name: 'DataReleaseStudyType', foreign_key_on: :self

        # @!attribute [r] data_release_study_type_id
        #   @return [Integer, nil] What sort of study is this?
        #   @note Exposing it as an attribute is for convenience.
        attribute :data_release_study_type_id

        # @!attribute [r] data_release_study_type_name
        #   @return [String, nil] Data release study type name
        #   @note Exposing it as an attribute is for convenience.
        #   @example 'genotyping or cytogenetics'
        attribute :data_release_study_type_name

        # @!attribute [r] reference_genome
        #   @return [ReferenceGenomeResource, nil] The reference genome
        #     associated with this study metadata.
        has_one :reference_genome, class_name: 'ReferenceGenome', foreign_key_on: :self

        # @!attribute [r] reference_genome_id
        #   @return [Integer, nil] Reference genome.
        #   @note Exposing it as an attribute is for convenience.
        attribute :reference_genome_id

        # @!attribute [r] reference_genome_name
        #   @return [String, nil] The reference genome name.
        #   @note Exposing it as an attribute is for convenience.
        #   @example 'Not suitable for alignment'
        attribute :reference_genome_name

        # @!attribute [r] array_express_accession_number
        #   @return [String, nil] ArrayExpress Accession Number.
        #   @example 'E-ERAD-123'
        attribute :array_express_accession_number

        # @!attribute [r] dac_policy
        #   @return [String, nil] Policy Url.
        #   @example 'https://www.sanger.ac.uk/about/research-policies/open-access-science/'
        attribute :dac_policy

        # @!attribute [r] ega_policy_accession_number
        #   @return [String, nil] EGA Policy Accession Number.
        #   @example 'EGAP12345678901'
        attribute :ega_policy_accession_number

        # @!attribute [r] ega_dac_accession_number
        #   @return [String, nil] EGA DAC Accession Number.
        #   @example 'EGAC12345678901'
        attribute :ega_dac_accession_number

        # @!attribute [r] commercially_available
        #   @return [String, nil] Are all the samples to be used in this study
        #     commercially available, unlinked anonymised cell-lines? (Yes or No)
        attribute :commercially_available

        # @!attribute [r] number_of_gigabases_per_sample
        #   @return [Float, nil] Number of gigabases per sample (minimum 0.15).
        attribute :number_of_gigabases_per_sample

        # @!attribute [r] hmdmc_approval_number
        #   @return [String, nil] HuMFre approval number.
        #   @example '01/00001'
        attribute :hmdmc_approval_number

        # @!attribute [r] created_at
        #   @return [String, nil] Metadata created timestamp.
        attribute :created_at

        # @!attribute [r] updated_at
        #   @return [String, nil] Metadata updated timestamp.
        attribute :updated_at

        # @!attribute [r] remove_x_and_autosomes
        #   @return [String, nil] Does this study require the removal of X
        #     chromosome and autosome sequence? (Yes or No)
        attribute :remove_x_and_autosomes

        # @!attribute [r] dac_policy_title
        #   @return [String, nil] Policy title.
        #   @example 'Wellcome Trust Sanger Institute Data Sharing Policy'
        attribute :dac_policy_title

        # @!attribute [r] separate_y_chromosome_data
        #   @return [Boolean, nil] Does this study require y chromosome data to
        #     be separated from x and autosomal data before archival?
        attribute :separate_y_chromosome_data

        # @!attribute [r] data_access_group
        #   @return [String, nil] Data access group.
        #   @example 'team001 cellgen cancer'
        attribute :data_access_group

        # @!attribute [r] prelim_id
        #   @return [String, nil] Prelim ID.
        #   @example 'G1234'
        attribute :prelim_id

        # @!attribute [r] program
        #   @return [ProgramResource, nil] The program associated with this
        #     study metadata.
        has_one :program, class_name: 'Program', foreign_key_on: :self

        # @!attribute [r] program_id
        #   @return [Integer, nil] Program.
        #   @note Exposing it as an attribute is for convenience.
        attribute :program_id

        # @!attribute [r] program_name
        #   @return [String, nil] The program name.
        #   @note Exposing it as an attribute is for convenience.
        #   @example 'Tree of Life'
        attribute :program_name

        # @!attribute [r] s3_email_list
        #   @return [String, nil] S3 email list.
        #   @example 'user1@example.com user2@example.com'
        attribute :s3_email_list

        # @!attribute [r] data_deletion_period
        #   @return [String, nil] Data deletion period.
        #   @example '3 months'
        attribute :data_deletion_period

        # @!attribute [r] contaminated_human_data_access_group
        #   @return [String, nil] Contaminated Human Data Access Group.
        #   @example 'rvidata'
        attribute :contaminated_human_data_access_group

        # @!attribute [r] data_release_prevention_other_comment
        #   @return [String, nil] Please explain the reason for preventing data release.
        #   @example 'Approved by Jane Doe; will release after genome assembly'
        attribute :data_release_prevention_other_comment

        # @!attribute [r] ebi_library_strategy
        #   @return [String, nil] EBI Library Strategy.
        #   @example 'RNA-Seq'
        attribute :ebi_library_strategy

        # @!attribute [r] ebi_library_source
        #   @return [String, nil] EBI Library Source.
        #   @example 'TRANSCRIPTOMIC SINGLE CELL'
        attribute :ebi_library_source

        # @!attribute [r] ebi_library_selection
        #   @return [String, nil] EBI Library Selection.
        #   @example 'Hybrid Selection'
        attribute :ebi_library_selection

        # @!attribute [r] data_release_timing_publication_comment
        #   @return [String, nil] When do you anticipate sharing the data?
        #   @example 'After first publication'
        attribute :data_release_timing_publication_comment

        # @!attribute [r] data_share_in_preprint
        #   @return [String, nil] Are you planning to share the data as part of
        #     a preprint? (Yes or No)
        attribute :data_share_in_preprint

        # Returns the associated study type name.
        #
        # @return [String, nil] The study type name, or nil if no study type is set.
        def study_type_name
          @model.study_type&.name
        end

        # Returns the associated data release study type name.
        #
        # @return [String, nil] The data release study type name, or nil if no data release study type is set.
        def data_release_study_type_name
          @model.data_release_study_type&.name
        end

        # Returns the associated reference genome name.
        #
        # @return [String, nil] The reference genome name, or nil if no reference genome is set.
        def reference_genome_name
          @model.reference_genome&.name
        end
      end
    end
  end
end
