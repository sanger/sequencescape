# frozen_string_literal: true

# Will construct a study
class UatActions::GenerateStudy < UatActions
  self.title = 'Generate study'
  self.description = 'Generate a simple study with the provided name.'
  self.category = :setup_and_test

  form_field :study_name, :text_field, label: 'Study Name', help: 'The name of the study.'

  def self.default
    new(study_name: UatActions::StaticRecords.study.name)
  end

  def perform
    study = create_study
    print_report(study)

    true
  end

  def create_study
    Study.create_with(
      state: 'active',
      study_metadata_attributes: {
        data_access_group: 'dag',
        study_type: UatActions::StaticRecords.study_type,
        faculty_sponsor: UatActions::StaticRecords.faculty_sponsor,
        data_release_study_type: UatActions::StaticRecords.data_release_study_type,
        study_description: 'A study generated for UAT',
        contaminated_human_dna: 'No',
        contains_human_dna: 'No',
        commercially_available: 'No',
        program: UatActions::StaticRecords.program
      }
    ).find_or_create_by!(name: study_name)
  end

  private

  def print_report(study)
    report['study_id'] = study.id
  end
end
