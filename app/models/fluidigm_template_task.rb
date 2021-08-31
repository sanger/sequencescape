# frozen_string_literal: true
class FluidigmTemplateTask < PlateTemplateTask # rubocop:todo Style/Documentation
  def partial
    'fluidigm_template_batches'
  end

  def plate_purpose_options(batch) # rubocop:todo Metrics/AbcSize
    requests = batch.requests.flat_map(&:next_requests)
    plate_purposes = requests.filter_map(&:request_type).uniq.map(&:acceptable_plate_purposes).flatten.uniq
    plate_purposes = # Fallback situation for the moment
      batch.requests.filter_map { |r| r.request_metadata.target_purpose }
    plate_purposes.map { |p| [p.name, p.size, p.id] }.sort
  end
end
