class LocationAssociation < ActiveRecord::Base
  belongs_to :locatable, :class_name => "Asset"
  belongs_to :location

  validates_uniqueness_of :locatable_id
  validates_presence_of :location_id, :locatable_id

  module Locatable
    def self.included(base)
      base.class_eval do
        has_one :location_association, :foreign_key => :locatable_id

        has_one :location, :through => :location_association
        delegate :location_id, :to => :location_association, :allow_nil => true

        named_scope :located_in, lambda { |location| {
          :joins => 'INNER JOIN `location_associations` ON `assets`.id=`location_associations`.`locatable_id`',
          :conditions => [ '`location_associations`.`location_id`=?', location.id ]
        } }

        # TODO:  not optimal
        def location_id=(l_id)
          location = l_id && Location.find(l_id)
          self.location = location
        end

      end
      base.extend(ClassMethods)
    end

    module ClassMethods
    end
  end
end
