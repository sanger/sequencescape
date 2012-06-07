
module Asset::Ownership

  module ChangesOwner

    # Included in events which change ownership of plates
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        after_create :assign_owner
      end
    end

    def assign_owner
      target_for_ownership.change_owner_to(user)
    end
    private :assign_owner

    module ClassMethods
      def set_target_for_owner(target)
        alias_method(:target_for_ownership, target)
      end
    end

  end

  module Unowned

    def change_owner_to(owner)
      # Do nothing
    end

  end

  module Owned
    # Currently only plates can be owned.

    class Owner < ActiveRecord::Base
      set_table_name('plate_owners')
      belongs_to :user
      belongs_to :plate
    end

    def self.included(base)
      base.class_eval do
        has_one :plate_owner, :class_name => 'Plate::Owner'
        has_one :owner, :source => :user, :through => :plate_owner
        named_scope :for_user, lambda { |user|
          {
            :joins => "LEFT OUTER JOIN `plate_owners` AS `for_usr_plate_owner` ON `for_usr_plate_owner`.plate_id = assets.id",
            :conditions => ["`for_usr_plate_owner`.user_id = ?", user.id]
          }
        }

      end
    end

    def change_owner_to(owner)
      update_attributes!(:owner => owner)
    end

  end

end