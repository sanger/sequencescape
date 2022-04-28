# frozen_string_literal: true
class FluidigmTemplateTask < PlateTemplateTask # rubocop:todo Style/Documentation
  def partial
    'fluidigm_template_batches'
  end

  def plate_purpose_options(batch) # rubocop:todo Metrics/AbcSize
    next_requests = batch.requests.flat_map(&:next_requests)
    plate_purposes = next_requests.filter_map(&:request_type).uniq.map(&:acceptable_purposes).flatten.uniq

    # If downstream requests don't specify an acceptable_purpose, fallback to any target purposes
    # on the current requests
    plate_purposes = batch.requests.filter_map { |r| r.request_metadata.target_purpose }.uniq if plate_purposes.empty?
    plate_purposes.map { |p| [p.name, p.size, p.id] }.sort
  end
end
