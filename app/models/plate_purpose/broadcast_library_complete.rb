#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2016 Genome Research Ltd.
module PlatePurpose::BroadcastLibraryComplete

  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    super
    prepare_library_complete(plate,user) if state == connect_on
  end

  private

  def prepare_library_complete(plate,user)
    orders = plate.orders_as_target.map(&:id)
    generate_events_for(plate,orders,user)
  end

  def generate_events_for(plate,orders,user)
    orders.each do |order_id|
      BroadcastEvent::PlateLibraryComplete.create!(:seed=>plate,:user=>user,:properties=>{:order_id=>order_id})
    end
  end

  def self.included(base)
    base.class_eval do
      class_attribute :connect_on
    end
  end
end
