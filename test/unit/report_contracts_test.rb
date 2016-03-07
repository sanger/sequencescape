#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
require './test/test_helper'

class ReportContractTest < ActiveSupport::TestCase

  # Contracted views are those we've agreed to maintain
  # We'll track all views in these tests, but this'll
  # pick up any that get 'dropped' by accident
  contracted_views = [
    'view_aliquots',
    'view_asset_links',
    'view_lanes',
    'view_library_tubes',
    'view_plates',
    'view_requests',
    'view_requests_new',
    'view_sample_study_reference_genome',
    'view_sample_tubes',
    'view_samples',
    'view_started_requests',
    'view_studies',
    'view_tags',
    'view_wells'
  ]

  ViewsSchema.all_views.concat(contracted_views).uniq.each do |view|
    context "View #{view}" do
      should "respond to Select * from" do
        assert ActiveRecord::Base.connection.execute("SELECT * FROM #{view};")
      end
    end
  end
end
