# frozen_string_literal: true

# Provides behaviour to walk downstream and remove aliquots from
# any downstream assets in the event of a retrospective fail.
module Aliquot::Remover
  def remove_downstream_aliquots
    # On the target asset of the failed request.
    on_downstream_aliquots(aliquots)
  end

  def on_downstream_aliquots(aliquots_to_remove)
    transfer_requests_as_source.each { |request| request.target_asset.process_aliquots(aliquots_to_remove) }
    requests_as_source.with_target.each { |request| request.target_asset.process_aliquots(aliquots_to_remove) }
  end

  def process_aliquots(aliquots_to_remove)
    new_aliquots = remove_matching_aliquots(aliquots_to_remove)
    on_downstream_aliquots(new_aliquots)
  end

  def remove_matching_aliquots(aliquots_to_remove)
    aliquots_to_remove.filter_map do |aliquot_to_remove|
      to_remove = aliquots.select { |aliquot| aliquot.matches?(aliquot_to_remove) }
      raise "Duplicate aliquots detected in asset #{display_name}." if to_remove.count > 1
      next unless to_remove.count == 1

      to_remove.first.tap(&:destroy)
    end
  end
end
