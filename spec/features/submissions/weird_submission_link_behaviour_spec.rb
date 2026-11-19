# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Weird submission link behaviour' do
  let(:admin) { create(:admin, login: 'admin', first_name: 'John', last_name: 'Doe') }
  let(:active_study) { create(:study, name: 'Study A', state: 'pending') }
  let(:pending_study) { create(:study, name: 'Study B', state: 'pending') }
  let(:first_submission_prompt) do
    'There are no submissions on this study yet. Please create your first submission'
  end
  let(:inactive_warning) { 'This study has not been activated yet.' }

  before do
    login_user(admin)
    active_study.activate!
    admin.roles << create(:manager_role, authorizable: active_study)
    active_study.samples.create!(name: 'Sample_A')
    admin.roles << create(:manager_role, authorizable: pending_study)
    pending_study.samples.create!(name: 'Sample_B')
  end

  it 'shows create-submission links on the active study but not the pending study' do
    # The Cucumber "study homepage" step visits information, not study_path.
    visit study_information_path(active_study)

    expect(page).to have_text(first_submission_prompt)
    expect(page).to have_text('Create Submission')
    expect(page).to have_no_text(inactive_warning)

    visit study_information_path(pending_study)

    expect(page).to have_text(inactive_warning)
    expect(page).to have_no_text(first_submission_prompt)
    expect(page).to have_no_text('Create Submission')
  end

  it 'shows create-submission links for an administrator who does not manage the study' do
    login_user(create(:admin, login: 'Barry', first_name: 'John', last_name: 'Doe', email: 'Barry@example.com'))
    visit study_information_path(active_study)

    expect(page).to have_text(first_submission_prompt)
    expect(page).to have_text('Create Submission')
    expect(page).to have_no_text(inactive_warning)
  end

  it 'keeps the sidebar link but not the first-submission prompt for an unrelated manager' do
    # The original step grants a global manager role, not a manager role on Study A
    # (nor a factory-created extra study).
    jon = create(
      :user,
      :with_role,
      role_name: 'manager',
      login: 'Jon',
      first_name: 'John',
      last_name: 'Doe',
      email: 'Jon@example.com'
    )
    login_user(jon)
    visit study_information_path(active_study)

    # Preserve the explicitly documented, undesirable sidebar behaviour.
    expect(page).to have_text('Create Submission')
    expect(page).to have_no_text(first_submission_prompt)
    expect(page).to have_no_text(inactive_warning)
  end
end
