# frozen_string_literal: true

# A standard validator for batches. It checks that all {Request requests} in the {Batch batch} are ready to be added to
# a batch, that the batch meets the minimum size, that the requests have the same read length, that the requests have
# the same flowcell type, and that the requests have the same target purpose.
class BatchCreationValidator < ActiveModel::Validator
  def validate(record)
    requests_have_same_read_length(record)
    requests_have_same_flowcell_type(record)
    batch_meets_minimum_size(record)
    all_requests_are_ready?(record)
    requests_have_same_target_purpose(record)
    requests_have_same_op_recipe(record) if record.pipeline.is_a?(UltimaSequencingPipeline)
  end

  private

  def all_requests_are_ready?(record)
    # Checks that SequencingRequests have at least one LibraryCreationRequest in passed status before being processed
    # (as referred by #75102998)
    record.errors.add :base, 'All requests must be ready to be added to a batch' unless record.requests.all?(&:ready?)
  end

  def batch_meets_minimum_size(record)
    return unless record.min_size && (record.requests.size < record.min_size)

    record.errors.add :base,
                      "You must create batches of at least #{record.min_size}
      requests in the pipeline #{record.pipeline.name}"
  end

  def requests_have_same_target_purpose(record)
    if record.pipeline.is_a?(CherrypickingPipeline) &&
        record.requests.map { |request| request.request_metadata.target_purpose_id }.uniq.size > 1
      record.errors.add(:base, 'The selected requests must have the same target purpose (Pick To) values')
    end
  end

  def requests_have_same_read_length(record)
    return if record.pipeline.is_read_length_consistent_for_batch?(record)

    record.errors.add :base, "The selected requests must have the same values in their 'Read length' field."
  end

  def requests_have_same_flowcell_type(record)
    return if record.pipeline.is_flowcell_type_consistent_for_batch?(record)

    record.errors.add :base, "The selected requests must have the same values in their 'Flowcell Requested' field."
  end

  def requests_have_same_op_recipe(record)
    return if record.pipeline.op_recipe_consistent_for_batch?(record)

    record.errors.add :base, "The selected requests must have the same values in their 'OT Recipe' field."
  end
end
