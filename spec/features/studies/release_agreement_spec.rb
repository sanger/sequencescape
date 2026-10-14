# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/release_agreement.feature
RSpec.describe 'Study release agreement', :js do
  include StudyFormHelper

  let(:user) { create(:admin, first_name: 'John', last_name: 'Smith') }
  let(:study_name) { 'Testing release agreements' }
  let(:standard_agreement_question) { "Will you be using WTSI's standard access agreement?" }

  before do
    create_study_form_reference_data
    enable_ui_study_creation
    login_user(user)
    visit new_study_path

    fill_in_study_details(
      name: study_name,
      description: 'Checking that release agreements behave properly',
      commercially_available: 'No'
    )
    fill_in 'Data access group', with: 'mygroup'
    choose_data_release_strategy('Managed (EGA)')
  end

  it 'creates the study when using the standard WTSI agreement' do
    choose_from_fieldset('Yes', standard_agreement_question)
    click_button 'Create'

    expect_to_be_on_information_page_for(study_name)
    expect(page).to have_text('Your study has been created')
  end

  it "doesn't create the study when using a non-standard agreement but no file is uploaded" do
    choose_from_fieldset('No', standard_agreement_question)
    click_button 'Create'

    expect(page).to have_current_path(studies_path)
    # TODO: Ideally this message would not mention the 'study metadata', but changing it affects the API messages.
    # Once we're fully upgraded we should look at the proper way of handling this.
    expect(page).to have_text("Study metadata data release non standard agreement can't be blank")
  end

  it 'creates the study when using a non-standard agreement with a file uploaded' do
    choose_from_fieldset('No', standard_agreement_question)
    attach_file('Please upload the access agreement that you will be using', Rails.root.join('test/data/blah.fasta'))
    click_button 'Create'

    expect_to_be_on_information_page_for(study_name)
    expect(page).to have_text('Your study has been created')
  end
end
