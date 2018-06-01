module PlatePurpose::BroadcastLibraryComplete
  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    super
    prepare_library_complete(plate, user) if state == connect_on
  end

  private

  def prepare_library_complete(plate, user)
    orders = plate.orders_as_target.pluck(:id)
    generate_events_for(plate, orders, user)
  end

  def generate_events_for(plate, orders, user)
    orders.each do |order_id|
      BroadcastEvent::PlateLibraryComplete.create!(seed: plate, user: user, properties: { order_id: order_id })
    end
  end

  def self.included(base)
    base.class_eval do
      class_attribute :connect_on
    end
  end
end
