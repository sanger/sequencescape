# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/5859843_create_study_owner_bug.feature
RSpec.describe 'Creating a study when a study owner has no name' do
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

  it 'still shows the create study form' do
    visit root_path
    click_link 'Create Study'

    expect(page).to have_text('To register a new study')
  end
end
