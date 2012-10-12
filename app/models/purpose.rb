class Purpose < ActiveRecord::Base
  set_table_name('plate_purposes')

  class Relationship < ActiveRecord::Base
    set_table_name('plate_purpose_relationships')
    belongs_to :parent, :class_name => 'Purpose'
    belongs_to :child, :class_name => 'Purpose'

    belongs_to :transfer_request_type, :class_name => 'RequestType'

    named_scope :with_parent, lambda { |plate_purpose| { :conditions => { :parent_id => plate_purpose.id } } }
    named_scope :with_child,  lambda { |plate_purpose| { :conditions => { :child_id  => plate_purpose.id } } }

    module Associations
      def self.included(base)
        base.class_eval do
          has_many :child_relationships, :class_name => 'Purpose::Relationship', :foreign_key => :parent_id, :dependent => :destroy
          has_many :child_purposes, :through => :child_relationships, :source => :child

          has_many :parent_relationships, :class_name => 'Purpose::Relationship', :foreign_key => :child_id, :dependent => :destroy
          has_many :parent_purposes, :through => :parent_relationships, :source => :parent
        end
      end

      # Returns the transfer request type to use between this purpose and the parent given
      def transfer_request_type_from(parent_purpose)
        parent_relationships.with_parent(parent_purpose).first.transfer_request_type
      end
    end
  end

  include Relationship::Associations
  include Uuid::Uuidable

  # There's a barcode printer type that has to be used to print the labels for this type of plate.
  belongs_to :barcode_printer_type

  def barcode_type
    barcode_printer_type.printer_type_id
  end

  # Things that are created are often in a default location!
  belongs_to :default_location, :class_name => 'Location'

  validates_format_of :name, :with => /^\w[\s\w._-]+\w$/i
  validates_presence_of :name
  validates_uniqueness_of :name, :message => "already in use"

  named_scope :where_is_a?, lambda { |clazz| { :conditions => { :type => [clazz,*Class.subclasses_of(clazz)].map(&:name) } } }

  def target_class
    @target_class ||= target_type.constantize
  end
  private :target_class
end
