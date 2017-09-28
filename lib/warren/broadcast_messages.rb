#
# Module Warren::BroadcastMessages provides methods to assist with
# setting up message broadcast
#
module Warren::BroadcastMessages
  module ClassMethods
    attr_reader :associated_to_broadcast
    def is_broadcast_via_warren
      after_commit :broadcast
    end

    def broadcasts_associated_via_warren(*associated)
      self.associated_to_broadcast = associated.freeze
      after_save :queue_associated_for_broadcast
    end
  end

  def self.included(base)
    base.class_eval do
      class_attribute :associated_to_broadcast, instance_writer: false
      extend ClassMethods
    end
  end

  def broadcast
    # Ideally we'd only check out once per transaction.
    # But that would mean monkey patching transaction.
    # Trying to avoid that for the moment.
    warren.with_chanel do |chanel|
      chanel << Warren::Message.new(self)
    end
  end

  def queue_associated_for_broadcast
    associated_to_broadcast.each do |association|
      send(association).try(:add_to_transaction)
    end
  end

  def routing_key
    nil
  end

  def warren
    Rails.application.config.warren
  end
end
