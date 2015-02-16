#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2014 Genome Research Ltd.
class Supplier < ActiveRecord::Base
  include Uuid::Uuidable
  include ::Io::Supplier::ApiIoSupport
  include SampleManifest::Associations

  has_many :studies, :through => :sample_manifests, :uniq => true
  validates_presence_of :name


  # Named scope for search by query string behaviour
  named_scope :for_search_query, lambda { |query,with_includes|
    {
      :conditions => [
        'suppliers.name IS NOT NULL AND (suppliers.name LIKE :like)', { :like => "%#{query}%", :query => query } ]
    }
  }

end
