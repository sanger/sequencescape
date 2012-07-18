
module Asset::Ownership

  module ChangesOwner

    # Included in events which change ownership of plates
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        after_create :assign_owner
        has_many :owners, :as => :eventable
      end
    end

    def assign_owner
      Array(target_for_ownership).map { |target| target.change_owner_to(user,self) }
    end
    private :assign_owner

    module ClassMethods
      def set_target_for_owner(target)
        alias_method(:target_for_ownership, target)
      end
    end
  end

  module Unowned
    def change_owner_to(owner,source_event)
      # Do nothing
    end
  end

  module Owned
    # Currently only plates can be owned.

    class Owner < ActiveRecord::Base
      set_table_name('plate_owners')
      belongs_to :user
      belongs_to :plate
      belongs_to :eventable, :polymorphic => true

      validates_presence_of :eventable
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

    def change_owner_to(owner,source_event)
      if plate_owner.nil?
        update_attributes!(:plate_owner => Owner.create!(:user => owner, :eventable => source_event, :plate => self))
      else
        plate_owner.update_attributes!(:user => owner, :eventable => source_event)
      end
    end
  end
end
