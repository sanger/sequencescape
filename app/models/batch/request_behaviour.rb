module Batch::RequestBehaviour
  def self.included(base)
    base.class_eval do
      has_one :batch_request
      has_one :batch, :through => :batch_request

      # For backwards compatibility
      def batch_requests; [batch_request].compact ; end
      def batches; [batch_request].compact ; end


      # Identifies all requests that are not part of a batch.
      named_scope :unbatched, {
        :joins      => 'LEFT OUTER JOIN batch_requests ubr ON `requests`.`id`=`ubr`.`request_id`',
        :readonly   => false,
        :conditions => '`ubr`.`request_id` IS NULL'
      }
      delegate :position, :to=>:batch_request, :allow_nil=>true
    end
  end

  def with_batch_id
    yield batch.id if batch.present?
  end

  def recycle_from_batch!
    ActiveRecord::Base.transaction do
      self.return_for_inbox!
      self.batch_request.destroy if self.batch_request.present?
      self.save!
    end
    #self.detach
    #self.batches -= [ batch ]
  end

  def return_for_inbox!
    # Valid for started, cancelled and pending batches
    # Will raise an exception outside of this
    self.cancel! if self.started?
    self.detach! unless self.pending?
  end

end
