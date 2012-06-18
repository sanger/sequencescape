module Aliquot::Remover
  class AliquotRecord
    # We can't use the aliquot itself, as it will have been destroyed by
    # the time we want to look at it. The aliquot record mimics
    # an aliquot in the comparison functions

    attr_reader :tag_id, :sample_id

    def initialize(aliquot)
      @tag_id = aliquot.tag_id
      @sample_id = aliquot.sample_id
    end

    def tagged?
      @tag_id != -1
    end

  end

  def remove_downstream_aliquots
    # On the target asset of the failed request.
    ActiveRecord::Base.transaction do
      target_aliquots = aliquots.map {|aliquot| AliquotRecord.new(aliquot)}
      on_downstream_aliquots(target_aliquots)
    end

  end

  def on_downstream_aliquots(aliquots_to_remove)
    requests_as_source.each do |request|
      request.target_asset.try(:process_aliquots,aliquots_to_remove)
    end
  end

  def process_aliquots(aliquots_to_remove)
    new_aliquots = remove_matching_aliquots(aliquots_to_remove)
    on_downstream_aliquots(new_aliquots)
  end

  def remove_matching_aliquots(aliquots_to_remove)
    aliquots_to_remove.map do |aliquot_to_remove|

      to_remove = aliquots.select do |aliquot|
        aliquot.matches?(aliquot_to_remove)
      end

      raise "Duplicate aliquots detected in asset #{display_name}." if to_remove.count > 1
      removed_aliquot = AliquotRecord.new(to_remove.first)
      to_remove.first.destroy
      removed_aliquot

    end
  end

end