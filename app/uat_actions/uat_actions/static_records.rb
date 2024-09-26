# frozen_string_literal: true

# Provides simple consistent records where multiple records are not needed.
module UatActions::StaticRecords
  # Swipecard code of the test user.
  # It gets hashed when persisted to the database, so we store it as a constant
  # here to allow us to access it in the integration suite tools.
  SWIPECARD_CODE = '__uat_test__'

  def self.collection_site
    'Sanger'
  end

  def self.supplier
    Supplier.find_or_create_by!(name: 'UAT Supplier')
  end

  def self.tube_purpose
    Purpose.create_with(target_type: 'SampleTube', type: 'Tube::Purpose', asset_shape_id: 1).find_or_create_by!(
      name: 'LCA Blood Vac'
    )
  end

  def self.study
    Study.create_with(
      state: 'active',
      study_metadata_attributes: {
        data_access_group: 'dag',
        study_type: study_type,
        faculty_sponsor: faculty_sponsor,
        data_release_study_type: data_release_study_type,
        study_description: 'A study generated for UAT',
        contaminated_human_dna: 'No',
        contains_human_dna: 'No',
        commercially_available: 'No',
        program: program
      }
    ).find_or_create_by!(name: 'UAT Study')
  end

  def self.study_type
    StudyType.create_with(valid_type: true, valid_for_creation: true).find_or_create_by!(name: 'UAT')
  end

  def self.data_release_study_type
    DataReleaseStudyType.default || DataReleaseStudyType.find_or_create_by(name: 'UAT')
  end

  def self.project
    Project.create_with(
      approved: true,
      state: 'active',
      project_metadata_attributes: {
        project_cost_code: 'FAKE1',
        project_funding_model: 'Internal',
        budget_division: budget_division
      }
    ).find_or_create_by!(name: 'UAT Project')
  end

  def self.budget_division
    BudgetDivision.find_or_create_by!(name: 'UAT TESTING')
  end

  def self.program
    Program.find_or_create_by!(name: 'UAT')
  end

  def self.user
    User.create_with(
      email: configatron.admin_email,
      first_name: 'Test',
      last_name: 'User',
      swipecard_code: SWIPECARD_CODE
    ).find_or_create_by(login: '__uat_test__')
  end

  def self.faculty_sponsor
    FacultySponsor.find_or_create_by!(name: 'UAT Faculty Sponsor')
  end
end
