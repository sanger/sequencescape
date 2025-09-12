# frozen_string_literal: true

# Specialized sequencing pipeline for Ultima
class UltimaSequencingPipeline < SequencingPipeline
  def op_recipe_consistent_for_batch?(batch) # rubocop:todo Metrics/AbcSize
    if batch.requests.empty? || batch.requests.first.request_metadata.nil?
      # No requests selected or the pipeline doesn't contain metadata to check
      return true
    end

    op_recipe_list = batch.requests.filter_map { |request| request.request_metadata.ot_recipe }

    # The pipeline doen't contain the ot_recipe attribute
    return true if op_recipe_list.empty?

    # There are some requests that don't have the ot_recipe attribute
    return false if op_recipe_list.size != batch.requests.size

    (op_recipe_list.uniq.size == 1)
  end
end
