# frozen_string_literal: true

# Specialized sequencing pipeline for Ultima
class UltimaSequencingPipeline < SequencingPipeline
  def ot_recipe_consistent_for_batch?(batch)
    ot_recipe_list = batch.requests.filter_map { |request| request.request_metadata.ot_recipe }

    # There are some requests that don't have the ot_recipe attribute
    return false if ot_recipe_list.size != batch.requests.size

    (ot_recipe_list.uniq.size == 1)
  end

  def wafer_size_consistent_for_batch?(batch)
    wafer_size_list = batch.requests.filter_map { |request| request.request_metadata.wafer_size }

    # There are some requests that don't have the wafer_size attribute
    return false if wafer_size_list.size != batch.requests.size

    (wafer_size_list.uniq.size == 1)
  end

  def post_release_batch(batch, _user)
    # Same logic as the superclass, but with a different Messenger root and template
    batch.assets.compact.uniq.each(&:index_aliquots)
    Messenger.create!(target: batch, template: 'UseqWaferIo', root: 'useq_wafer')
  end
end
