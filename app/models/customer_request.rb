# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

# A class for requests that have some business meaning outside of Sequencescape
class CustomerRequest < Request
  self.customer_request = true

  def update_responsibilities!
    return if qc_metrics.stock_metric.empty?
    customer_accepts_responsibility! if qc_metrics.stock_metric.all?(&:poor_quality_proceed)
  end

  def customer_accepts_responsibility!
    request_metadata.update_attributes!(customer_accepts_responsibility: true)
  end

  delegate :customer_accepts_responsibility, :customer_accepts_responsibility=, to: :request_metadata
end
