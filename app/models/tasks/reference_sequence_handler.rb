# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Tasks::ReferenceSequenceHandler
  def render_reference_sequence_task(task, params)
    @assets = task.find_batch_requests(params[:batch_id]).map { |request| request.asset }.uniq
  end

  def do_reference_sequence_task(_task, params)
    ActiveRecord::Base.transaction do
      params[:asset].each do |asset_id, protocol_id|
        protocol = ReferenceGenome.find(protocol_id).name
        if protocol.blank?
          flash[:warning] = 'All samples must have a protocol selected'
          return false
        end

        Asset.find(asset_id).pac_bio_library_tube_metadata.update_attributes!(protocol: protocol)
      end
    end

    true
  end
end
