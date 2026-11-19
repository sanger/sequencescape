# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Batch side links for each pipeline' do
  include BatchFeatureHelpers

  it 'shows Edit but neither stock-label printing nor stock-tube creation for Cherrypick' do
    user = create(:user, :with_role, role_name: 'internal', login: 'user', first_name: 'John', last_name: 'Doe')
    user.grant_lab_manager
    login_user(user)
    pipeline = create_batch_feature_pipeline('Cherrypick')
    batch = create(:batch, pipeline: pipeline, state: 'pending', production_state: nil)

    visit batch_path(batch)
    expect(page).to have_current_path(batch_path(batch))

    expect(page).to have_text('Edit')
    expect(page).to have_no_text('Print stock labels')
    expect(page).to have_no_text('Create stock tubes')
  end
end
