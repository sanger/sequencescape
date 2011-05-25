class Tag < ActiveRecord::Base
  acts_as_audited :on => [:destroy, :update]
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  belongs_to :tag_group
  has_many :assets, :as => :material
  has_many :requests, :through => :assets, :uniq => true

  named_scope :sorted , :order => "map_id ASC"
  named_scope :including_associations_for_json, { :include => [ :uuid_object, { :tag_group => [:uuid_object] } ] }
  
  def self.render_class
    Api::TagIO
  end
  
  def name
    "Tag #{map_id}"
  end

  # Creates an instance of this tag that can be attached to a well.
  def create!
    TagInstance.create!(:tag => self)
  end
end
