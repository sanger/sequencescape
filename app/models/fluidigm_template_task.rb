class FluidigmTemplateTask < PlateTemplateTask
  def partial
    'fluidigm_template_batches'
  end

  def plate_purpose_options(batch)
    requests       = batch.requests.flat_map(&:next_requests)
    plate_purposes = requests.map(&:request_type).compact.uniq.map(&:acceptable_plate_purposes).flatten.uniq
    if plate_purposes.empty?
      plate_purposes = batch.requests.map do |r|
        r.request_metadata.target_purpose
      end.compact.uniq
    end # Fallback situation for the moment
    plate_purposes.map { |p| [p.name, p.size, p.id] }.sort
  end
end
