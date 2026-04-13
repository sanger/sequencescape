# frozen_string_literal: true

# Specialized sequencing pipeline for Ultima UG200
class UltimaUG200SequencingPipeline < UltimaSequencingPipeline
  def wafer_size_consistent_for_batch?(batch)
    wafer_size_list = batch.requests.filter_map { |request| request.request_metadata.wafer_size }

    # There are some requests that don't have the wafer_size attribute
    return false if wafer_size_list.size != batch.requests.size

    (wafer_size_list.uniq.size == 1)
  end
end
