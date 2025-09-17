# frozen_string_literal: true

# Specialized sequencing pipeline for Ultima
class UltimaSequencingPipeline < SequencingPipeline
  def ot_recipe_consistent_for_batch?(batch)
    batch.requests.map { |r| r.request_metadata&.ot_recipe }

    ot_recipe_list = batch.requests.filter_map { |request| request.request_metadata.ot_recipe }

    # The pipeline doen't contain the ot_recipe attribute
    return true if ot_recipe_list.empty?

    # There are some requests that don't have the ot_recipe attribute
    return false if ot_recipe_list.size != batch.requests.size

    (ot_recipe_list.uniq.size == 1)
  end
end
