# frozen_string_literal: true

# Provides simple consistent records where multiple records are not needed.
module UatActions::StaticRecords
  def self.study
    Study.create_with(
      state: 'active',
      study_metadata_attributes: {
        data_access_group: 'dag',
        study_type: StudyType.first,
        faculty_sponsor: faculty_sponsor,
        data_release_study_type: DataReleaseStudyType.default,
        study_description: 'A study generated for UAT',
        contaminated_human_dna: 'No',
        contains_human_dna: 'No',
        commercially_available: 'No',
        program: program
      }
    ).find_or_create_by!(name: 'UAT Study')
  end

  def self.project
    Project.find_or_create_by!(name: 'UAT Study')
  end

  def self.program
    Program.find_or_create_by!(name: 'UAT')
  end

  def self.user
    User.create_with(
      email: configatron.admin_email,
      first_name: 'Test',
      last_name: 'User',
      swipecard_code: '__uat_test__'
    ).find_or_create_by(login: '__uat_test__')
  end

  def self.faculty_sponsor
    FacultySponsor.find_or_create_by!(name: 'UAT Faculty Sponsor')
  end
end
