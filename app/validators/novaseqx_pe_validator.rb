# frozen_string_literal: true

# A custom batch creation validator for NovaSeqX PE pipeline
class NovaseqxPeValidator < ActiveModel::Validator
  def validate(record)
    batch_size_for_flowcell_type(record)
  end

  private

  def batch_size_for_flowcell_type(record)
    if record.requests.empty? || record.requests.first.request_metadata.nil?
      # No requests selected or the pipeline doesn't contain metadata to check
      return true
    end

    flowcell_type_list = record.requests.filter_map { |request| request.request_metadata.requested_flowcell_type }

    return true if flowcell_type_list.empty?

    # There is a flowcell type uniqueness test in batch creation validator so we don't worry about error messages here
    return false if flowcell_type_list.uniq.size > 1

    flowcells_match_batch_size(record, flowcell_type_list.first)
  end

  def flowcells_match_batch_size(record, flowcell_type)
    case flowcell_type
    when '1.5B'
      if record.requests.size != 2
        record.errors.add(:base, 'You must select exactly 2 requests for 1.5B flowcells')
        false
      end
    when '10B', '25B'
      if record.requests.size != 8
        record.errors.add(:base, "You must select exactly 8 requests for #{flowcell_type} flowcells")
        false
      end
    end
  end
end
