# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015 Genome Research Ltd.

module Asset::Ownership
  module ChangesOwner
    # Included in events which change ownership of plates
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        after_create :assign_owner
        has_many :owners, as: :eventable
      end
    end

    def assign_owner
      [target_for_ownership].flatten.map { |target| target.change_owner_to(user, self) }
    end
    private :assign_owner

    module ClassMethods
      def set_target_for_owner(target)
        alias_method(:target_for_ownership, target)
      end
    end
  end

  module Unowned
    def change_owner_to(owner, source_event)
      # Do nothing
    end
  end

  module Owned
    # Currently only plates can be owned.

    def self.included(base)
      base.class_eval do
        has_one :plate_owner
        has_one :owner, source: :user, through: :plate_owner

         scope :for_user, ->(user) {
            joins(:plate_owner)
            .where(plate_owners: { user_id: user })
                          }
      end
    end

    def change_owner_to(owner, source_event)
      if plate_owner.nil?
        update_attributes!(plate_owner: PlateOwner.create!(user: owner, eventable: source_event, plate: self))
      else
        plate_owner.update_attributes!(user: owner, eventable: source_event)
      end
    end
  end
end
