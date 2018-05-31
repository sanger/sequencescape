# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015,2016 Genome Research Ltd.

# Gets included in the WorkflowsController and adds a load of methods
# to handle the first step of cherrypicking (selecting templates etc.)
# Not a great pattern to follow, although its very prevalent in the workflows.
module Tasks::PlateTemplateHandler
  def render_plate_template_task(task, _params)
    @robots = Robot.all
    @plate_purpose_options = task.plate_purpose_options(@batch)
    suitable_sizes = @plate_purpose_options.map { |o| o[1] }.uniq
    @plate_templates = PlateTemplate.with_sizes(suitable_sizes)
  end

  def self.generate_spreadsheet(batch)
    CSV.generate(row_sep: "\r\n") do |csv|
      csv << ['Request ID', 'Sample Name', 'Source Plate', 'Source Well', 'Plate', 'Destination Well']
      batch.requests.each { |r| csv << [r.id, r.asset.sample.name, r.asset.plate.human_barcode, r.asset.map_description, '', ''] }
    end
  end
end
