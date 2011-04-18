class Io::Sample < Core::Io::Base
  set_model_for_input(::Sample)
  set_json_root(:sample)
  set_eager_loading { |model| model.include_sample_metadata.include_studies }
  
  define_attribute_and_json_mapping(%Q{
                                           name <=> name
                               sanger_sample_id <=> sanger_id
                                        control <=> control
 
                       sample_metadata.organism <=> organism
                         sample_metadata.cohort <=> cohort
              sample_metadata.country_of_origin <=> country_of_origin
            sample_metadata.geographical_region <=> geographical_region
                      sample_metadata.ethnicity <=> ethnicity
                         sample_metadata.volume <=> volume
              sample_metadata.supplier_plate_id <=> supplier_plate_id
                         sample_metadata.mother <=> mother
                         sample_metadata.father <=> father
                      sample_metadata.replicate <=> replicate
                     sample_metadata.gc_content <=> gc_content
                         sample_metadata.gender <=> gender
                     sample_metadata.dna_source <=> dna_source
             sample_metadata.sample_public_name <=> public_name
             sample_metadata.sample_common_name <=> common_name
              sample_metadata.sample_strain_att <=> strain_att
                sample_metadata.sample_taxon_id <=> taxon_id
    sample_metadata.sample_ebi_accession_number <=> ebi_accession_number
             sample_metadata.sample_description <=> description
                sample_metadata.sample_sra_hold <=> sra_hold
                   sample_reference_genome_name <=> reference_genome
  })
end
