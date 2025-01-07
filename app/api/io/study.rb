# frozen_string_literal: true
# Controls API V1 IO for Study
class Io::Study < Core::Io::Base
  set_model_for_input(::Study)
  set_json_root(:study)
  set_eager_loading { |model| model.include_study_metadata.include_projects }

  define_attribute_and_json_mapping(
    '
                                           name     => name
                             ethically_approved     => ethically_approved
                                          state     => state
                                   abbreviation     => abbreviation

                 study_metadata.study_type.name     => type
            study_metadata.faculty_sponsor.name     => sac_sponsor
           study_metadata.reference_genome.name     => reference_genome
      study_metadata.study_ebi_accession_number     => accession_number
               study_metadata.study_description     => description
                  study_metadata.study_abstract     => abstract

          study_metadata.contaminated_human_dna     => contaminated_human_dna
         study_metadata.remove_x_and_autosomes?     => remove_x_and_autosomes
      study_metadata.separate_y_chromosome_data     => separate_y_chromosome_data
              study_metadata.contains_human_dna     => contains_human_dna
          study_metadata.commercially_available     => commercially_available
    study_metadata.data_release_study_type.name     => data_release_sort_of_study
           study_metadata.data_release_strategy     => data_release_strategy
study_metadata.contaminated_human_data_access_group => contaminated_human_data_access_group
  '
  )
end
