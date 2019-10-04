# This module contains methods associated with the now defunct Illumina-B pipleine.
#
# This module was used to generate the purposes and their associations as part of
# both the seeds and the original migration.
#
# Removal of this code shouldn't affect production, but will disrupt seeds,
# and potentially a number of cucumber features. It will probably also require
# the corresponding search objects to be deprecated.
#
# @todo #2396 Remove
module IlluminaB::PlatePurposes
  PLATE_PURPOSE_FLOWS = [
    %w(
      ILB_STD_INPUT
      ILB_STD_COVARIS
      ILB_STD_SH
      ILB_STD_PREPCR
      ILB_STD_PCR
      ILB_STD_PCRR
      ILB_STD_PCRXP
      ILB_STD_PCRRXP
    )
  ].freeze

  TUBE_PURPOSE_FLOWS = [
    %w[
      ILB_STD_STOCK
      ILB_STD_MX
    ]
  ].freeze

  QC_TUBE_PURPOSE_FLOWS = [].freeze

  BRANCHES = [
    %w(ILB_STD_INPUT ILB_STD_COVARIS ILB_STD_SH ILB_STD_PREPCR ILB_STD_PCR ILB_STD_PCRXP ILB_STD_STOCK ILB_STD_MX),
    %w(ILB_STD_PREPCR ILB_STD_PCRR ILB_STD_PCRRXP ILB_STD_STOCK)
  ].freeze

  STOCK_PLATE_PURPOSE = 'ILB_STD_INPUT'.freeze

  # Don't have ILllumina B QC plates at the momnet...
  PLATE_PURPOSE_LEADING_TO_QC_PLATES = [].freeze

  STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST = {
    'ILB_STD_INPUT' => 'illumina_b_std'
  }.freeze

  OUTPUT_PLATE_PURPOSES = [].freeze

  PLATE_PURPOSE_TYPE = {
    'ILB_STD_INPUT' => PlatePurpose::Input,
    'ILB_STD_COVARIS' => PlatePurpose::InitialPurpose,
    'ILB_STD_SH' => PlatePurpose,
    'ILB_STD_PREPCR' => PlatePurpose,
    'ILB_STD_PCR' => PlatePurpose,
    'ILB_STD_PCRXP' => IlluminaHtp::FinalPlatePurpose,
    'ILB_STD_PCRR' => PlatePurpose,
    'ILB_STD_PCRRXP' => IlluminaHtp::FinalPlatePurpose,
    'ILB_STD_STOCK' => IlluminaHtp::StockTubePurpose,
    'ILB_STD_MX' => IlluminaB::MxTubePurpose
  }.freeze

  def self.request_type_prefix
    'Illumina-B'
  end

  extend IlluminaHtp::PlatePurposes::PurposeHelpers
end

# We require all the plate and tube purpose files here as Rails eager loading does not play nicely with single table
# inheritance
require_dependency 'app/models/illumina_b/mx_tube_purpose'
