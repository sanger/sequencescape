# frozen_string_literal: true

require 'rails_helper'
require_relative 'batch_feature_helpers'

RSpec.describe 'Batch progression' do
  include BatchFeatureHelpers

  let(:user) { create(:user, :with_role, role_name: 'internal', login: 'me', first_name: 'John', last_name: 'Doe') }
  let(:pipeline) { create_batch_feature_pipeline('MiSeq sequencing') }

  before { login_user(user) }

  it 'releases the last completed batch and records the user in its events' do
    batch = create(:batch, pipeline: pipeline, state: 'completed', production_state: nil)

    visit release_batch_path(batch)

    within('div#batch_events') do
      expect(page).to have_text('Released')
      expect(page).to have_text('me')
    end
    expect(batch.reload.state).to eq('released')
    expect(batch.lab_events.find_by!(description: 'Released').user).to eq(user)
  end

  it 'finishes the last started batch and records the user in its events' do
    batch = create(:batch, pipeline: pipeline, state: 'started', production_state: nil)

    visit finish_batch_path(batch)
    visit batch_path(batch)

    within('div#batch_events') do
      expect(page).to have_text('Complete')
      expect(page).to have_text('me')
    end
    expect(batch.reload.state).to eq('completed')
    expect(batch.lab_events.find_by!(description: 'Complete').user).to eq(user)
  end
end
