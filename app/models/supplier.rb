# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

class Supplier < ActiveRecord::Base
  include Uuid::Uuidable
  include ::Io::Supplier::ApiIoSupport
  include SampleManifest::Associations
  include SharedBehaviour::Named

  has_many :studies, ->() { distinct }, through: :sample_manifests
  validates_presence_of :name

 # Named scope for search by query string behaviour
 scope :for_search_query, ->(query, _with_includes) {
    where(['suppliers.name IS NOT NULL AND (suppliers.name LIKE :like)', { like: "%#{query}%", query: query }])
                          }
end
