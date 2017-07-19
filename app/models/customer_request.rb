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
end

# how do observers work here?
# this one fixed the tests, but does not seem in line with how it worked before
CustomerRequest.add_observer CustomerRequestObserver.instance

# Sti is a pain when it comes to rails and subclasses in development mode.
# This was an attempt to fix that issue, but was resulting in circular dependencies in
# rails 5.
# require_dependency 'pooled_cherrypick_request'
# require_dependency 'illumina_b/requests'
# require_dependency 'illumina_c/requests'
# require_dependency 'illumina_htp/requests'
# require_dependency 'pulldown/requests'
# require_dependency 'control_request'
# require_dependency 'genotyping_request'
# require_dependency 'library_creation_request'
# require_dependency 'pac_bio_sample_prep_request'
# require_dependency 'pac_bio_sequencing_request'
# require_dependency 'pooled_cherrypick_request'
# require_dependency 'pulldown_multiplexed_library_creation_request'
# require_dependency 'qc_request'
# require_dependency 'sequencing_request'
# require_dependency 'strip_creation_request'
# require_dependency 'request/multiplexing'
