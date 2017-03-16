# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2015,2016 Genome Research Ltd.

# We require all the plate and tube purpose files here as Rails eager loading does not play nicely with single table
# inheritance

module Pulldown::PlatePurposes
  ISCH_PURPOSE_FLOWS = [[
      'Lib PCR-XP',
      'ISCH lib pool',
      'ISCH hyb',
      'ISCH cap lib',
      'ISCH cap lib PCR',
      'ISCH cap lib PCR-XP',
      'ISCH cap lib pool'
  ]]

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
  ]

  PLATE_PURPOSE_TYPE = {
    'ISCH lib pool'       => Pulldown::InitialDownstreamPlatePurpose,
    'ISCH hyb'            => IlluminaHtp::DownstreamPlatePurpose,
    'ISCH cap lib'        => IlluminaHtp::DownstreamPlatePurpose,
    'ISCH cap lib PCR'    => IlluminaHtp::DownstreamPlatePurpose,
    'ISCH cap lib PCR-XP' => IlluminaHtp::DownstreamPlatePurpose,
    'ISCH cap lib pool'   => IlluminaHtp::DownstreamPlatePurpose
  }

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
  ]

  PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES = [
    ['Lib PCR-XP',   'ISCH lib pool', 'TransferRequest::InitialTransfer'],
    ['Lib PCRR-XP',  'ISCH lib pool', 'TransferRequest::InitialTransfer']
  ]

  STOCK_PLATE_PURPOSES = ['WGS stock DNA', 'SC stock DNA', 'ISC stock DNA']

  class << self
    def create_purposes(branch_o)
      branch = branch_o.clone
      initial = Purpose.find_by!(name: branch.shift)
      branch.inject(initial) do |parent, new_purpose_name|
        Pulldown::PlatePurposes::PLATE_PURPOSE_TYPE[new_purpose_name].create!(name: new_purpose_name).tap do |child_purpose|
          parent.child_relationships.create!(child: child_purpose, transfer_request_type: request_type_between(parent, child_purpose))
        end
      end
    end

    def request_type_between(parent, child)
      _, _, request_class = self::PLATE_PURPOSES_TO_REQUEST_CLASS_NAMES.detect { |a, b, _| (parent.name == a) && (child.name == b) }
      return RequestType.transfer if request_class.nil?
      return RequestType.initial_transfer if request_class == :initial
      request_type_name = "Illumina A #{parent.name}-#{child.name}"
      RequestType.create!(name: request_type_name, key: request_type_name.gsub(/\W+/, '_'), request_class_name: request_class, asset_type: 'Well', order: 1)
    end
    private :request_type_between
  end
end

%w(initial_downstream_plate initial_plate library_plate).each do |type|
  require_dependency "app/models/pulldown/#{type}_purpose"
end
