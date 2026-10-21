# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/5859843_create_study_owner_bug.feature
describe 'Creating a study when a study owner has no name' do
  include StudyFormHelper

  let(:admin) { create(:admin, first_name: 'John', last_name: 'Smith') }
  let!(:study) { create(:study, name: 'Test study', state: 'active') }

  before do
    create_study_form_reference_data
    enable_ui_study_creation

    owner_with_name = create(:user, login: 'xyz1', first_name: 'John', last_name: 'Smith')
    owner_without_name = create(:user, login: 'xyz2', first_name: '', last_name: '')
    owner_with_name.grant_role('owner', study)
    owner_without_name.grant_role('owner', study)
    owner_without_name.update!(first_name: nil, last_name: nil)

    login_user(admin)
  end

  it 'shows the create study form, listing only the owners that have a last name' do
    visit root_path
    expect(page).to have_current_path(root_path)

    click_link 'Create Study'

    expect(page).to have_text('To register a new study')
    expect(page).to have_select('study_owner_id', with_options: ['John Smith'])
    expect(page).to have_no_select('study_owner_id', with_options: ['xyz2'])
  end
end
