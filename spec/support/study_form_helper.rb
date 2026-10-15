# frozen_string_literal: true

# Helpers shared by the feature specs that drive the 'Create Study' form.
# Include it in a spec with `include StudyFormHelper`.
module StudyFormHelper
  HUMAN_DNA_QUESTION = 'Do any of the samples in this study contain human DNA?'
  CONTAMINATED_DNA_QUESTION =
    'Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?'
  COMMERCIALLY_AVAILABLE_QUESTION =
    'Are all the samples to be used in this study commercially available, unlinked anonymised cell-lines?'
  DATA_RELEASE_STRATEGY_QUESTION = 'What is the data release strategy for this study?'

  # Reference data that the seeds provide to the Cucumber suite, but which RSpec has to create itself.
  # Uses find_or_create_by! because the study factory also creates 'General' and 'genomic sequencing', so the
  # records may already exist if a study has been created first.
  def create_study_form_reference_data
    FacultySponsor.find_or_create_by!(name: 'Jack Sponsor')
    Program.find_or_create_by!(name: 'General')
    create(:study_type)
    DataReleaseStudyType.find_or_create_by!(name: 'genomic sequencing')
  end

  # Study creation through the UI is hidden behind a feature flag.
  def enable_ui_study_creation
    Flipper.disable(:y26_192_prevent_ui_study_creation)
  end

  def choose_from_fieldset(value, fieldset)
    within_fieldset(fieldset) { choose(value, allow_label_click: true) }
  end

  def choose_data_release_strategy(strategy)
    choose_from_fieldset(strategy, DATA_RELEASE_STRATEGY_QUESTION)
  end

  # Fills in the mandatory fields of the form (everything except the data release strategy and timing).
  def fill_in_study_details(name:, description:, human_dna: 'No', commercially_available: 'Yes')
    fill_in 'Study name', with: name
    select 'Jack Sponsor', from: 'Faculty Sponsor'
    select 'General', from: 'Program'
    select 'WGS', from: 'EBI Library Strategy'
    select 'GENOMIC', from: 'EBI Library Source'
    select 'PCR', from: 'EBI Library Selection'
    fill_in 'Study description', with: description
    choose_from_fieldset(human_dna, HUMAN_DNA_QUESTION)
    choose_from_fieldset('No', CONTAMINATED_DNA_QUESTION)
    choose_from_fieldset(commercially_available, COMMERCIALLY_AVAILABLE_QUESTION)
  end

  # Waits for the redirect to the new study's information page, then checks it is the right study.
  def expect_to_be_on_information_page_for(study_name)
    expect(page).to have_current_path(%r{/studies/\d+/information})
    expect(page).to have_current_path(study_information_path(Study.find_by!(name: study_name)))
  end
end
