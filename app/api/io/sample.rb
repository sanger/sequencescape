# frozen_string_literal: true
# Controls API V1 IO for Sample
class Io::Sample < Core::Io::Base
  set_model_for_input(::Sample)
  set_json_root(:sample)
  set_eager_loading { |model| model.include_sample_metadata.include_studies }

  define_attribute_and_json_mapping(
    '
                                    sm_container <= container
                                           name  => sanger.name
                               sanger_sample_id  => sanger.sample_id
                 sample_metadata.is_resubmitted <=> sanger.resubmitted
             sample_metadata.sample_description <=> sanger.description

                  sample_metadata.supplier_name <=> supplier.sample_name
      sample_metadata.sample_storage_conditions <=> supplier.storage_conditions

      sample_metadata.date_of_sample_collection <=> supplier.collection.date

      sample_metadata.date_of_sample_extraction <=> supplier.extraction.date
       sample_metadata.sample_extraction_method <=> supplier.extraction.method

                sample_metadata.sample_purified <=> supplier.purification.purified
            sample_metadata.purification_method <=> supplier.purification.method

                         sample_metadata.volume <=> supplier.measurements.volume
                  sample_metadata.concentration <=> supplier.measurements.concentration
                     sample_metadata.gc_content <=> supplier.measurements.gc_content
                         sample_metadata.gender <=> supplier.measurements.gender
    sample_metadata.concentration_determined_by <=> supplier.measurements.concentration_determined_by

                     sample_metadata.dna_source <=> source.dna_source
                         sample_metadata.cohort <=> source.cohort
              sample_metadata.country_of_origin <=> source.country
            sample_metadata.geographical_region <=> source.region
                      sample_metadata.ethnicity <=> source.ethnicity
                                        control <=> source.control

                         sample_metadata.mother <=> family.mother
                         sample_metadata.father <=> family.father
                      sample_metadata.replicate <=> family.replicate
                        sample_metadata.sibling <=> family.sibling

                sample_metadata.sample_taxon_id <=> taxonomy.id
              sample_metadata.sample_strain_att <=> taxonomy.strain
             sample_metadata.sample_common_name <=> taxonomy.common_name
                       sample_metadata.organism <=> taxonomy.organism
                   sample_reference_genome_name <=> reference.genome

    sample_metadata.sample_ebi_accession_number <=> data_release.accession_number
                    sample_metadata.sample_type <=> data_release.sample_type

                sample_metadata.sample_sra_hold  => data_release.visibility
             sample_metadata.sample_public_name <=> data_release.public_name
             sample_metadata.sample_description <=> data_release.description

                       sample_metadata.genotype <=> data_release.metagenomics.genotype
                      sample_metadata.phenotype <=> data_release.metagenomics.phenotype
                            sample_metadata.age <=> data_release.metagenomics.age
            sample_metadata.developmental_stage <=> data_release.metagenomics.developmental_stage
                      sample_metadata.cell_type <=> data_release.metagenomics.cell_type
                  sample_metadata.disease_state <=> data_release.metagenomics.disease_state
                       sample_metadata.compound <=> data_release.metagenomics.compound
                           sample_metadata.dose <=> data_release.metagenomics.dose
              sample_metadata.immunoprecipitate <=> data_release.metagenomics.immunoprecipitate
               sample_metadata.growth_condition <=> data_release.metagenomics.growth_condition
                           sample_metadata.rnai <=> data_release.metagenomics.rnai
                  sample_metadata.organism_part <=> data_release.metagenomics.organism_part
                     sample_metadata.time_point <=> data_release.metagenomics.time_point
                      sample_metadata.treatment <=> data_release.metagenomics.treatment
                        sample_metadata.subject <=> data_release.metagenomics.subject
                        sample_metadata.disease <=> data_release.metagenomics.disease

                      sample_metadata.treatment <=> data_release.managed.treatment
                        sample_metadata.subject <=> data_release.managed.subject
                        sample_metadata.disease <=> data_release.managed.disease
  '
  )
end
