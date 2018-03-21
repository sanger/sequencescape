# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

# A template is effectively a partially constructed Transfer instance, containing only the
# transfers that should be made and the final Transfer class that should be constructed.
#
# For pulldown there are at least a couple of these templates:
# - several plate-to-plate transfers of various columns (but all rows)
# - one whole plate to tube transfer
class TransferTemplate < ApplicationRecord
  include Uuid::Uuidable

  # A name is a useful way to identify templates!
  validates_presence_of :name
  validates_uniqueness_of :name

  # A template creates a particular Transfer subclass.
  validates_presence_of :transfer_class_name

  # A set of transfers that should be made.
  serialize :transfers

  def transfer_class
    @transfer_class ||= transfer_class_name.constantize
  end

  def self.transfer_constructor(name)
    line = __LINE__ + 1
    class_eval("
      def #{name}(attributes)
        attributes.merge!(:transfers => self.transfers) unless self.transfers.blank?
        transfer_class.#{name}(attributes)
      end
    ", __FILE__, line)
  end

  transfer_constructor(:create!)
  transfer_constructor(:preview!)
end
