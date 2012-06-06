
module Plate::Ownership

  module ChangeOwner
    # Included in events which change ownership of plates
    def self.included(base)
      base.class_eval do

        after_create :assign_plate_owner
        def assign_plate_owner
          target_for_ownership.change_owner_to(user)
        end
        private :assign_plate_owner

      end
    end
  end

  class Owner < ActiveRecord::Base
    set_table_name('plate_owners')
    belongs_to :user
    belongs_to :plate
  end

  def self.included(base)
    base.class_eval do
      has_one :plate_owner, :class_name => 'Plate::Owner'
      has_one :owner, :source => :user, :through => :plate_owner
      named_scope :for_user, lambda { |user_id|
        {
          :joins => "LEFT OUTER JOIN `plate_owners` AS `fusr_plate_owner` ON `fusr_plate_owner`.plate_id = assets.id",
          :conditions => ["`fusr_plate_owner`.user_id = ?", user_id]
        }
      }

    end
  end
  def change_owner_to(owner)
    update_attributes!(:owner => owner)
  end

end