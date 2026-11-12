# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/5976844_add_question_on_study_for_ethical_approvals.feature
describe 'Studies pending ethical approval', :js do
  include StudyFormHelper

  let(:user) { create(:admin, login: 'user') }

  before do
    create_study_form_reference_data
    create(:study_type, name: 'Clone Sequencing')
    enable_ui_study_creation
    login_user(user)
    visit root_path
  end

  def fill_in_study_form(**answers)
    fill_in_study_details(name: 'new study', description: 'writing cukes', **answers)
    fill_in 'ENA Study Accession Number', with: '12345678'
    fill_in 'Study name abbreviation', with: 'CCC3435'
    select 'Clone Sequencing', from: 'Study Type'
    choose_data_release_strategy('Open (ENA)')
  end

  # Creates 'new study' through the UI with the given answers to the human DNA questions
  def create_study(**answers)
    click_link 'Create Study'
    expect(page).to have_text('Study Create')
    expect(page).to have_text(StudyFormHelper::COMMERCIALLY_AVAILABLE_QUESTION)
    fill_in_study_form(**answers)
    click_button 'Create'
    expect_to_be_on_information_page_for('new study')
    expect(Study.find_by!(name: 'new study').abbreviation).to eq('CCC3435')
  end

  def list_studies_pending_ethical_approval
    click_link 'Studies'
    click_link 'Pending ethical approval', exact: true
  end

  # A study needs ethical approval only when it contains human DNA, is not contaminated with human DNA
  # and its samples are not commercially available.
  it 'lists a study with human DNA that is not contaminated and not commercially available' do
    create_study(human_dna: 'Yes', contaminated_dna: 'No', commercially_available: 'No')
    list_studies_pending_ethical_approval

    expect(page).to have_css('table#study_list a', text: 'new study')
  end

  [
    %w[Yes No Yes],
    %w[Yes Yes No],
    %w[Yes Yes Yes],
    %w[No No No],
    %w[No No Yes],
    %w[No Yes No],
    %w[No Yes Yes]
  ].each do |human_dna, contaminated_dna, commercially_available|
    it "does not list a study with human DNA: #{human_dna}, contaminated: #{contaminated_dna}, " \
       "commercially available: #{commercially_available}" do
      create_study(human_dna:, contaminated_dna:,
                   commercially_available:)
      list_studies_pending_ethical_approval

      # With a single study in the database, an empty list proves it was not selected
      expect(page).to have_text('No studies match your selection.')
    end
  end
end
