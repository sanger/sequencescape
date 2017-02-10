# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

class PacBioSamplePrepPipeline < Pipeline
  INBOX_PARTIAL               = 'group_by_parent'
  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def inbox_partial
    INBOX_PARTIAL
  end

  def allow_tag_collision_on_tagging_task?
    false
  end

  def inbox_eager_loading
    :loaded_for_grouped_inbox_display
  end

  def post_release_batch(batch, _user)
    cancel_sequencing_requests_on_library_failure(batch)
    cancel_excess_sequencing_requests(batch)
  end

  def cancel_downstream_requests(request)
    request.next_requests(self).each { |sequencing_request| sequencing_request.cancel_from_upstream! }
  end

  def cancel_sequencing_requests_on_library_failure(batch)
    batch.requests.each do |request|
      if request.failed?
        cancel_downstream_requests(request)
      end
    end
  end

  def cancel_excess_sequencing_requests(batch)
    batch.requests.each do |request|
      smrt_cells_available = request.target_asset.pac_bio_library_tube_metadata.smrt_cells_available
      smrt_cells_requested = number_of_smrt_cells_requested(request)
      next if smrt_cells_available.nil? || smrt_cells_requested.nil?
      if smrt_cells_available < smrt_cells_requested
        cancel_excess_downstream_requests(request, (smrt_cells_requested - smrt_cells_available))
      end
    end
  end

  def cancel_excess_downstream_requests(request, number_to_cancel)
    request.next_requests(self).each_with_index do |sequencing_request, index|
      sequencing_request.cancel_from_upstream! if index < number_to_cancel
    end
  end

  def number_of_smrt_cells_requested(request)
    request.next_requests(self).count
  end

  # PacBio pipelines do not require their batches to record the position of their requests.
  def requires_position?
    false
  end
end
