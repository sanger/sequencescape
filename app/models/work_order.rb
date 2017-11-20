# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

# A work order groups requests together based on submission and asset
# providing a unified interface for external applications.
# It is likely that its behaviour will be extended in future
class WorkOrder < ApplicationRecord
  has_many :requests
  belongs_to :work_order_type, required: true

  # where.not(work_order_id: nil assists the MySQL query optimizer as otherwise is seems
  # to get confused by the large number of null entries in requests.work_order_id
  has_one :example_request, ->() { order(id: :asc).where.not(work_order_id: nil).readonly }, class_name: 'CustomerRequest'
  has_one :study, through: :example_request, source: :initial_study
  has_one :project, through: :example_request, source: :initial_project
  has_one :source_receptacle, through: :example_request, source: :asset

  has_many :samples, ->() { distinct }, through: :example_request

  # Will hopefully be variable in the future
  def quantity_units
    'flowcells'
  end

  def quantity_value
    requests.count
  end

  def state=(new_state)
    super
    requests.each do |request|
      request.state = new_state
      request.save!
    end
  end

  def at_risk
    example_request.customer_accepts_responsibility
  end

  def at_risk=(risk)
    requests.each do |request|
      request.customer_accepts_responsibility = risk
      request.save!
    end
  end

  def options=(new_options)
    requests.each do |request|
      request.request_metadata_attributes = new_options
      request.save!
    end
  end
end
