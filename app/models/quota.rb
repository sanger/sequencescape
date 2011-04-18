class Quota < ActiveRecord::Base
  belongs_to :project
  belongs_to :request_type
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable
  
  acts_as_audited :on => [:destroy, :update]
  
  named_scope :request_type, lambda {|*args| {:conditions => { :request_type_id => args[0]} } }
  named_scope :including_associations_for_json, { :include => [ :uuid_object, { :project => :uuid_object }, :request_type ] }
  
  def self.render_class
    Api::QuotaIO
  end
end
