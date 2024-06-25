# frozen_string_literal: true

class BatchValidator < ActiveModel::Validator

  def validate(record)
    requests_have_same_read_length(record)
    requests_have_same_flowcell_type(record)
    batch_meets_minimum_size(record)
    all_requests_are_ready?(record)
    requests_have_same_target_purpose(record)
  end

  private

  def all_requests_are_ready?(record)
    # Checks that SequencingRequests have at least one LibraryCreationRequest in passed status before being processed
    # (as referred by #75102998)
    record.errors.add :base, 'All requests must be ready to be added to a batch' unless record.requests.all?(&:ready?)
  end

  # rubocop:disable Style/GuardClause
  def batch_meets_minimum_size(record)
    if record.min_size && (record.requests.size < record.min_size)
      record.errors.add :base, "You must create batches of at least #{record.min_size}
        requests in the pipeline #{record.pipeline.name}"
    end
  end

  def requests_have_same_target_purpose(record)
    if record.pipeline.is_a?(CherrypickingPipeline) &&
      record.requests.map { |request| request.request_metadata.target_purpose_id }.uniq.size > 1

      record.errors.add(:base, 'The selected requests must have the same target purpose (Pick To) values')
    end
  end

  def requests_have_same_read_length(record)
    unless record.pipeline.is_read_length_consistent_for_batch?(self)
      record.errors.add :base, "The selected requests must have the same values in their 'Read length' field."
    end
  end

  def requests_have_same_flowcell_type(record)
    unless record.pipeline.is_flowcell_type_consistent_for_batch?(self)
      record.errors.add :base, "The selected requests must have the same values in their 'Flowcell Requested' field."
    end
  end
  # rubocop:enable Style/GuardClause
end