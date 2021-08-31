# frozen_string_literal: true
ActiveRecord::SchemaDumper.ignore_tables = %w[
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
  view_started_requests
  view_studies
  view_tags
  view_wells
]
