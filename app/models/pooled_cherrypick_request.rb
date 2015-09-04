#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class PooledCherrypickRequest < Request

  # Returns a list of attributes that must match for any given pool.
  # We don't want to place any restrictions on Cherrypicking (Yet).
  def shared_attributes
    ""
  end

  def transfer_aliquots
    target_asset.aliquots << aliquots_for_transfer_to(target_asset).map do |aliquot|
      aliquot.clone.tap do |clone|
        clone.study_id   = initial_study_id   || aliquot.study_id
        clone.project_id = initial_project_id || aliquot.project_id
      end
    end
  end

  private

  def aliquots_for_transfer_to(target_asset)
    asset.aliquots.reject do |candidate_aliquot|
      target_asset.aliquots.any? {|existing_aliquot| existing_aliquot.equivalent?(candidate_aliquot) }
    end
  end

end
