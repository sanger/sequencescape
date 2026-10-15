# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/study_state.feature
describe 'Study state' do
  let(:user) { create(:admin, first_name: 'John', last_name: 'Smith') }
  let!(:study) { create(:study, name: 'Test study', state: 'active') }

  before { login_user(user) }

  it 'allows an active study to be deactivated' do
    visit study_information_path(study)
    expect(page).to have_current_path(study_information_path(study))
    expect(page).to have_text('Deactivate Study')

    click_link 'Deactivate Study'
    fill_in 'Reason for deactivation', with: 'some reason'
    click_button 'Deactivate'

    expect(page).to have_text('This study has been deactivated: some reason')
    expect(study.reload).to be_inactive
    expect(study.comments.last.description).to eq('some reason')
  end
end
