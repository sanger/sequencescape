# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2014,2015 Genome Research Ltd.

class OrderPresenter
  attr_accessor :study_id, :project_name, :plate_purpose_id, :sample_names_text, :lanes_of_sequencing_required, :comments

  def initialize(order)
    @target_order = order
  end

  # id needs to be defined to stop Object#id being called on the OrderPresenter
  # instance.
  def id
    @target_order.id
  end

  def method_missing(method, *args, &block)
    @target_order.send(method, *args, &block)
  end
end
