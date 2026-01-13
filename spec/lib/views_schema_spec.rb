# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ViewsSchema' do
  # Contracted views are those we've agreed to maintain
  # We'll track all views in these tests, but this'll
  # pick up any that get 'dropped' by accident
  contracted_views = %w[
    view_aliquots
    view_asset_links
    view_lanes
    view_library_tubes
    view_plates
    view_requests
    view_requests_new
    view_sample_study_reference_genome
    view_sample_tubes
    view_samples
    view_studies
    view_tags
    view_wells
  ]

  (ViewsSchema.all_views + contracted_views).uniq.each do |view|
    describe "View #{view}" do
      it 'exists in the database' do
        expect { ActiveRecord::Base.connection.execute("SELECT * FROM #{view};") }.not_to raise_error
      end
    end
  end
end
