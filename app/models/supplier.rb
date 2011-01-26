class Supplier < ActiveRecord::Base
  include Uuid::Uuidable
  include ::Io::Supplier::ApiIoSupport

  has_many :sample_manifests
  has_many :studies, :through => :sample_manifests, :uniq => true
  validates_presence_of :name
  acts_as_audited :on => [:destroy, :update]

  # Named scope for search by query string behaviour
  named_scope :for_search_query, lambda { |query|
    {
      :conditions => [
        'suppliers.name IS NOT NULL AND (suppliers.name LIKE :like)', { :like => "%#{query}%", :query => query } ]
    }
  }

end
