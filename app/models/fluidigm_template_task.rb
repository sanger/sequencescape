class FluidigmTemplateTask < PlateTemplateTask

  def partial
    "fluidigm_template_batches"
  end

  def plate_purpose_options(batch)
    requests       = batch.requests.map { |r| r.submission ? r.submission.next_requests(r) : [] }.flatten
    plate_purposes = requests.map(&:request_type).compact.uniq.map(&:acceptable_plate_purposes).flatten.uniq
    plate_purposes = batch.requests.map { |r| r.request_metadata.target_purpose }.compact.uniq if plate_purposes.empty?  # Fallback situation for the moment
    plate_purposes.map { |p| [p.name, p.id] }.sort
  end

end
