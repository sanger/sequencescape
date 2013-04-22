module ModelExtensions::Plate
  module NamedScopeHelpers
    def include_plate_named_scope(plate_association)
      named_scope :"include_#{plate_association}", {
        :include => { plate_association.to_sym => ::ModelExtensions::Plate::PLATE_INCLUDES }
      }
    end
  end

  PLATE_INCLUDES = [
    :plate_metadata, {
      :wells => [
        :map,
        :transfer_requests_as_target,
        :uuid_object
      ]
    }
  ]

  def self.included(base)
    base.class_eval do
      named_scope :include_plate_purpose, :include => :plate_purpose
      named_scope :include_plate_metadata, :include => :plate_metadata
      delegate :pool_id_for_well, :to => :plate_purpose, :allow_nil => true
    end
  end

  def plate_purpose_or_stock_plate
    self.plate_purpose || PlatePurpose.find_by_name('Stock Plate')
  end

  # Returns a hash from the submission for the pools to the wells that form that pool on this plate.  This is
  # not necessarily efficient but it is correct.  Unpooled wells, those without submissions, are completely
  # ignored within the returned result.
  def pools
    ActiveSupport::OrderedHash.new.tap do |pools|
      Request.include_request_metadata.for_pooling_of(self).each do |request|
        pools[request.pool_id] = { :wells => request.pool_into.split(',') }.tap do |pool_information|
          request.update_pool_information(pool_information)
        end unless request.pool_id.nil?
      end
    end
  end

  # Adds pre-capture pooling information, we need to delegate this to the stock plate, as we need all the wells
  def pre_cap_groups
    ActiveSupport::OrderedHash.new.tap do |groups|
      Request.include_request_metadata.for_pre_cap_grouping_of(self.stock_plate||self).each do |request|
        groups[request.group_id] = { :wells => request.group_into.split(',') }.tap do |pool_information|
          pool_information[:pre_capture_plex_level] ||= request.order.request_options['pre_capture_plex_level'].to_i
        end unless request.group_id.nil?
      end
    end
  end

end
