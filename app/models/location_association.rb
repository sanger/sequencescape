# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

class LocationAssociation < ActiveRecord::Base
  belongs_to :locatable, class_name: 'Asset'
  belongs_to :location

  validates_uniqueness_of :locatable_id
  validates :location_id, :locatable_id, presence: true

  after_save :update_locatable

  def update_locatable
    locatable.touch
  end

  module Locatable
    def self.included(base)
      base.class_eval do
        has_one :location_association, foreign_key: :locatable_id, inverse_of: :locatable

        has_one :location, through: :location_association
        delegate :location_id, to: :location_association, allow_nil: true

       scope :located_in, ->(location) {
          joins(:location_association).where(location_associations: { location_id: location })
                          }

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
