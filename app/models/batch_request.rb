class BatchRequest < ActiveRecord::Base
  include Api::BatchRequestIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  belongs_to :batch
  belongs_to :request

  named_scope :ordered, :order => 'position ASC'
  named_scope :at_position, lambda { |position| { :conditions => { :position => position } } }

  # Ensure that any requests that are added have a position that is unique and incremental in the batch,
  # unless we're moving them around in the batch, in which case we assume it'll be valid.
  attr_accessor :sorting_requests_within_batch
  alias_method(:sorting_requests_within_batch?, :sorting_requests_within_batch)

  delegate :requires_position?, :to => :batch

  def need_to_check_position?
    requires_position? and not sorting_requests_within_batch?
  end
  private :need_to_check_position?

  validates_numericality_of :position, :only_integer => true, :if => :requires_position?
  validates_uniqueness_of :position, :scope => :batch_id, :if => :need_to_check_position?
  before_validation(:if => :requires_position?) { |record| record.position ||= (record.batch.batch_requests.map(&:position).compact.max || 0) + 1 }

  def move_to_position!(position)
    update_attributes!(:sorting_requests_within_batch => true, :position => position)
  end
end
