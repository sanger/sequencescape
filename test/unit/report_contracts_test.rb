# frozen_string_literal: true

require './test/test_helper'

class ReportContractTest < ActiveSupport::TestCase
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

  ViewsSchema
    .all_views
    .concat(contracted_views)
    .uniq
    .each do |view|
      context "View #{view}" do
        should 'respond to Select * from' do
          assert ActiveRecord::Base.with_connection do |connection|
            connection.execute("SELECT * FROM #{view};")
          end
        end
      end
    end
end
