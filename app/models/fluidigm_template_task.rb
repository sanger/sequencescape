class FluidigmTemplateTask < PlateTemplateTask # rubocop:todo Style/Documentation
  def partial
    'fluidigm_template_batches'
  end

  def plate_purpose_options(batch) # rubocop:todo Metrics/AbcSize
    requests = batch.requests.flat_map(&:next_requests)
    plate_purposes = requests.map(&:request_type).compact.uniq.map(&:acceptable_plate_purposes).flatten.uniq
    plate_purposes = batch.requests.map { |r| r.request_metadata.target_purpose }.compact.uniq if plate_purposes.empty? # Fallback situation for the moment
    plate_purposes.map { |p| [p.name, p.size, p.id] }.sort
  end
end
