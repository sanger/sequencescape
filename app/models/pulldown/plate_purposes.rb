# We require all the plate and tube purpose files here as Rails eager loading does not play nicely with single table
# inheritance

# This module contains methods associated with the now defunct Pulldown pipleine.
#
# This module was used to generate the purposes and their associations as part of
# both the seeds and the original migration.
#
# Removal of this code shouldn't affect production, but will disrupt seeds,
# and potentially a number of cucumber features. It will probably also require
# the corresponding search objects to be deprecated.
#
# @todo #2396 Remove
module Pulldown::PlatePurposes
  ISCH_PURPOSE_FLOWS = [[
    'Lib PCR-XP',
    'ISCH lib pool',
    'ISCH hyb',
    'ISCH cap lib',
    'ISCH cap lib PCR',
    'ISCH cap lib PCR-XP',
    'ISCH cap lib pool'
  ]].freeze

  PLATE_PURPOSE_FLOWS = [
    [
      'WGS stock DNA',
      'WGS Covaris',
      'WGS post-Cov',
      'WGS post-Cov-XP',
      'WGS lib',
      'WGS lib PCR',
      'WGS lib PCR-XP',
      'WGS lib pool'
    ], [
      'SC stock DNA',
      'SC Covaris',
      'SC post-Cov',
      'SC post-Cov-XP',
      'SC lib',
      'SC lib PCR',
      'SC lib PCR-XP',
      'SC hyb',
      'SC cap lib',
      'SC cap lib PCR',
      'SC cap lib PCR-XP',
      'SC cap lib pool'
    ], [
      'ISC stock DNA',
      'ISC Covaris',
      'ISC post-Cov',
      'ISC post-Cov-XP',
      'ISC lib',
      'ISC lib PCR',
      'ISC lib PCR-XP',
      'ISC lib pool',
      'ISC hyb',
      'ISC cap lib',
      'ISC cap lib PCR',
      'ISC cap lib PCR-XP',
      'ISC cap lib pool'
    ], ISCH_PURPOSE_FLOWS.first
  ].freeze

  PLATE_PURPOSE_TYPE = {
    'ISCH lib pool' => Pulldown::InitialDownstreamPlatePurpose,
    'ISCH hyb' => IlluminaHtp::DownstreamPlatePurpose,
    'ISCH cap lib' => IlluminaHtp::DownstreamPlatePurpose,
    'ISCH cap lib PCR' => IlluminaHtp::DownstreamPlatePurpose,
    'ISCH cap lib PCR-XP' => IlluminaHtp::DownstreamPlatePurpose,
    'ISCH cap lib pool' => IlluminaHtp::DownstreamPlatePurpose
  }.freeze

  PLATE_PURPOSE_LEADING_TO_QC_PLATES = [
    'WGS post-Cov',
    'WGS post-Cov-XP',
    'WGS lib PCR-XP',

    'SC post-Cov',
    'SC post-Cov-XP',
    'SC lib PCR-XP',
    'SC cap lib PCR-XP',

    'ISC post-Cov',
    'ISC post-Cov-XP',
    'ISC lib PCR-XP',
    'ISC cap lib PCR-XP'
  ].freeze

  STOCK_PLATE_PURPOSES = ['WGS stock DNA', 'SC stock DNA', 'ISC stock DNA'].freeze

  class << self
    def create_purposes(branch)
      initial = Purpose.find_by!(name: branch.first)
      branch[1..-1].inject(initial) do |parent, new_purpose_name|
        Pulldown::PlatePurposes::PLATE_PURPOSE_TYPE[new_purpose_name].create!(name: new_purpose_name).tap do |child_purpose|
          parent.child_relationships.create!(child: child_purpose)
        end
      end
    end
  end
end

%w(initial_downstream_plate initial_plate library_plate).each do |type|
  require_dependency "app/models/pulldown/#{type}_purpose"
end
