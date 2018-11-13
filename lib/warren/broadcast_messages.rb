require_relative 'message'
require_relative 'queue_broadcast_message'
#
# Module Warren::BroadcastMessages provides methods to assist with
# setting up message broadcast
#
module Warren::BroadcastMessages
  module ClassMethods
    attr_reader :associated_to_broadcast

    #
    # Records of this type are broadcast via RabbitMQ when a transaction is closed.
    #
    # @return [void]
    #
    def broadcast_via_warren
      after_commit :queue_for_broadcast
    end

    #
    # When records of this type are saved, broadcast the associated records
    #
    # @param [Symbol,Array<Symbol>] *associated One or more symbols indicating the associations to broadcast.
    #
    # @return [void]
    #
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

  def queue_for_broadcast
    # Message rendering is slow in some cases. This
    # broadcasts an initial lightweight message which can
    # be picked up and rendered asynchronously
    # Borrows connection as per #broadcast
    warren << Warren::QueueBroadcastMessage.new(self)
  end

  def broadcast
    # This results in borrowing a connection from the pool
    # per-message. Which isn't ideal. Ideally we'd either
    # check out a connection per thread or per transaction.
    # Any checked out connections will need to be checked back
    # in once the thread/transaction ends with high reliability.
    # So we're doing things the easy way until:
    # 1) Performance requires something more complicated
    # 2) We find a way to achieve the above without monkey-patching
    #    or other complexity (Its probably possible)
    warren << Warren::Message.new(self)
  end

  #
  # After save callback: configured via broadcasts_associated_via_warren
  # Adds any associated records to the transaction, ensuring their after commit
  # methods will fire.
  #
  # @return [void]
  #
  def queue_associated_for_broadcast
    associated_to_broadcast.each do |association|
      send(association).try(:add_to_transaction)
    end
  end

  #
  # Returns the configured warren
  #
  #
  # @return [#<<,#with_chanel,#connect] The configure warren.
  #
  def warren
    Warren.handler
  end
end
