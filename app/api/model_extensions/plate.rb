# Included in {Plate}
# The intent of this file was to provide methods specific to the V1 API
module ModelExtensions::Plate
  module NamedScopeHelpers
    def include_plate_named_scope(plate_association)
      scope :"include_#{plate_association}", -> { includes(plate_association.to_sym => ::ModelExtensions::Plate::PLATE_INCLUDES) }
    end
  end

  PLATE_INCLUDES = [
    :plate_metadata, {
      wells: %i[
        map
        transfer_requests_as_target
        uuid_object
      ]
    }
  ].freeze

  def self.included(base)
    base.class_eval do
      scope :include_plate_purpose, -> { includes(:plate_purpose) }
      scope :include_plate_metadata, -> { includes(:plate_metadata) }
      delegate :pool_id_for_well, to: :plate_purpose, allow_nil: true
    end
  end

  def source_plate
    plate_purpose.source_plate(self)
  end

  def source_plates
    plate_purpose.source_plates(self)
  end

  def library_source_plate
    plate_purpose.library_source_plate(self)
  end

  def library_source_plates
    plate_purpose.library_source_plate(self)
  end

  # Returns a hash from the submission for the pools to the wells that form that pool on this plate.  This is
  # not necessarily efficient but it is correct.  Unpooled wells, those without submissions, are completely
  # ignored within the returned result.
  def pools
    Request.include_request_metadata.for_pooling_of(self).each_with_object({}) do |request, pools|
      pools[request.pool_id] = {
        wells: request.pool_into.split(','),
        pool_complete: request.pool_complete == 1
      }.tap do |pool_information|
        request.update_pool_information(pool_information)
      end unless request.pool_id.nil?
    end
  end

  # Adds pre-capture pooling information, we need to delegate this to the stock plate, as we need all the wells
  # Currently used in {Transfer::BetweenPlates} to set submission id, we should switch to doing this
  # directly via Limber with transfer request collections
  def pre_cap_groups
    Request.include_request_metadata.for_pre_cap_grouping_of(self).each_with_object({}) do |request, groups|
      groups[request.group_id] = { wells: request.group_into.split(',') }.tap do |pool_information|
        pool_information[:pre_capture_plex_level] ||= request.request_metadata.pre_capture_plex_level
        # We supply the submission id to assist with correctly tagging transfer requests later
        pool_information[:submission_id] ||= request.submission_id
      end unless request.group_id.nil?
    end
  end
end
