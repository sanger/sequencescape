# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class FluidigmTemplateTask < PlateTemplateTask
  def partial
    'fluidigm_template_batches'
  end

  def plate_purpose_options(batch)
    requests       = batch.requests.map { |r| r.submission ? r.submission.next_requests(r) : [] }.flatten
    plate_purposes = requests.map(&:request_type).compact.uniq.map(&:acceptable_plate_purposes).flatten.uniq
    plate_purposes = batch.requests.map { |r| r.request_metadata.target_purpose }.compact.uniq if plate_purposes.empty? # Fallback situation for the moment
    plate_purposes.map { |p| [p.name, p.size, p.id] }.sort
  end
end
