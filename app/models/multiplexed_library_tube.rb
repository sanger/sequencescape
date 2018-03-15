# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015,2016 Genome Research Ltd.
require_dependency 'tube/purpose'

class MultiplexedLibraryTube < Tube
  include ModelExtensions::MultiplexedLibraryTube
  include Api::MultiplexedLibraryTubeIO::Extensions
  include Transfer::Associations

  has_many :order_roles, ->() { distinct }, through: :requests_as_target

  # Transfer requests into a tube are direct requests where the tube is the target.
  def transfer_requests
    transfer_requests_as_target
  end

  # You can do sequencing with this asset type, even though the request types suggest otherwise!
  def is_sequenceable?
    true
  end

  def library_prep?
    true
  end

  # Returns the type of asset that can be considered appropriate for request types.
  def asset_type_for_request_types
    LibraryTube
  end

  def creation_requests
    direct = requests_as_target.where_is_a?(Request::LibraryCreation)
    return direct unless direct.empty?
    parents.includes(:creation_request).map(&:creation_request)
  end

  def team
    creation_requests.first&.request_type&.product_line&.name
  end

  def library_source_plates
    purpose.library_source_plates(self)
  end

  def role
    order_roles.first.try(:role)
  end

  def self.stock_asset_type
    StockMultiplexedLibraryTube
  end

  def self.stock_asset_purpose
    Tube::Purpose.stock_mx_tube
  end

  extend Asset::Stock::CanCreateStockAsset
end
