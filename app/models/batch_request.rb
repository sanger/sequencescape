#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2015 Genome Research Ltd.
class BatchRequest < ActiveRecord::Base
  include Api::BatchRequestIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  belongs_to :batch
  belongs_to :request, :inverse_of => :batch_request

  scope :ordered, -> { order('position ASC') }
  scope :at_position, ->(position) { { :conditions => { :position => position } } }

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

  # Each request can only belong to one batch.
  validates_uniqueness_of :request_id, :message => '%{value} is already in a batch.'
  before_validation(:if => :requires_position?) { |record| record.position ||= (record.batch.batch_requests.map(&:position).compact.max || 0) + 1 }

  def move_to_position!(position)
    update_attributes!(:sorting_requests_within_batch => true, :position => position)
  end
end
