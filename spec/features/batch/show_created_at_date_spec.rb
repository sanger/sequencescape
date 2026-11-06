# frozen_string_literal: true

require 'rails_helper'
require_relative 'batch_feature_helpers'

RSpec.describe 'Batch creation date' do
  include BatchFeatureHelpers

  ['Cherrypick', 'MiSeq sequencing'].each do |pipeline_name|
    it "shows Created at and the pipeline for a pending #{pipeline_name} batch" do
      user = create(:user, :with_role, role_name: 'internal', login: 'user', first_name: 'John', last_name: 'Doe')
      login_user(user)
      pipeline = create_batch_feature_pipeline(pipeline_name)
      batch = create(:batch, pipeline: pipeline, state: 'pending', production_state: nil)

      visit batch_path(batch)
      expect(page).to have_current_path(batch_path(batch))

      expect(page).to have_text('Created at')
      expect(page).to have_text("Pipeline #{pipeline_name}")
    end
  end
end
