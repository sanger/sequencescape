class AssetLink < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 500
  acts_as_dag_links :node_class_name => 'Asset'
  include Uuid::Uuidable
  
  named_scope :including_associations_for_json, { :include => [:uuid_object, { :ancestor => :uuid_object }, { :descendant  => :uuid_object }] }

  def self.render_class
    Api::AssetLinkIO
  end

  def destroy!
  end
end
