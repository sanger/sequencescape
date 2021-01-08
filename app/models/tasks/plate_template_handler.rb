# frozen_string_literal: true

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
      batch.requests.each do |r|
        csv << [r.id, r.asset.samples.first&.name, r.asset.plate.human_barcode, r.asset.map_description, '', '']
      end
    end
  end
end
