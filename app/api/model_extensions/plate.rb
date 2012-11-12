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
      Request.find_by_sql(%Q{
        SELECT uuids.external_id AS pool_id, GROUP_CONCAT(DISTINCT pw_location.description SEPARATOR ',') AS pool_into, requests.*
        FROM container_associations
        INNER JOIN assets AS pw        ON container_associations.content_id=pw.id
        INNER JOIN maps AS pw_location ON pw.map_id=pw_location.id
        INNER JOIN well_links          ON well_links.target_well_id=pw.id AND well_links.type='stock'
        INNER JOIN requests            ON well_links.source_well_id=requests.asset_id
        INNER JOIN submissions         ON requests.submission_id=submissions.id
        INNER JOIN uuids               ON uuids.resource_id=submissions.id AND uuids.resource_type='Submission'
        WHERE container_associations.container_id=#{id}
        GROUP BY submissions.id
      }).each do |request|
        pools[request.pool_id] = { :wells => request.pool_into.split(',') }.tap do |pool_information|
          request.update_pool_information(pool_information)
        end unless request.pool_id.nil?
      end
    end
  end
end
