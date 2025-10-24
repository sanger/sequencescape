# frozen_string_literal: true
# Included in {Plate}
# The intent of this file was to provide methods specific to the V1 API
module ModelExtensions::Plate
  # module NamedScopeHelpers
  #   def include_plate_named_scope(plate_association)
  #     scope :"include_#{plate_association}",
  #           lambda { includes(plate_association.to_sym => ::ModelExtensions::Plate::PLATE_INCLUDES) }
  #   end
  # end

  PLATE_INCLUDES = [:plate_metadata, { wells: %i[map transfer_requests_as_target uuid_object] }].freeze

  def self.included(base)
    base.class_eval do
      # scope :include_plate_purpose, -> { includes(:plate_purpose) }
      # scope :include_plate_metadata, -> { includes(:plate_metadata) }
      delegate :pool_id_for_well, to: :plate_purpose, allow_nil: true
    end
  end

  def library_source_plate
    plate_purpose.library_source_plate(self)
  end

  def library_source_plates
    plate_purpose.library_source_plate(self)
  end

  # Adds pre-capture pooling information, we need to delegate this to the stock plate, as we need all the wells
  # Currently used in {Transfer::BetweenPlates} to set submission id, we should switch to doing this
  # directly via Limber with transfer request collections
  def pre_cap_groups # rubocop:todo Metrics/AbcSize
    Request
      .include_request_metadata
      .for_pre_cap_grouping_of(self)
      .each_with_object({}) do |request, groups|
        groups[request.group_id] = { wells: request.group_into.split(',') }.tap do |pool_information|
          pool_information[:pre_capture_plex_level] ||= request.request_metadata.pre_capture_plex_level

          # We supply the submission id to assist with correctly tagging transfer requests later
          pool_information[:submission_id] ||= request.submission_id
        end unless request.group_id.nil?
      end
  end
end
