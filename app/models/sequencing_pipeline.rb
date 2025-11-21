# frozen_string_literal: true

# SequencingPipeline represents the loading of multiplexed library tubes onto
# lanes of flowcells for running on the Sequencing machines.
class SequencingPipeline < Pipeline
  self.batch_worksheet = 'simplified_worksheet'
  self.sequencing = true
  self.purpose_information = false
  self.inbox_eager_loading = :loaded_for_sequencing_inbox_display
  self.generate_target_assets_on_batch_create = true
  self.asset_type = 'Lane::Labware'
  self.requires_position = true

  def request_actions
    [:remove]
  end

  def is_read_length_consistent_for_batch?(batch) # rubocop:todo Metrics/AbcSize
    if (batch.requests.size == 0) || batch.requests.first.request_metadata.nil?
      # No requests selected or the pipeline doesn't contain metadata to check
      return true
    end

    read_length_list = batch.requests.filter_map { |request| request.request_metadata.read_length }

    # The pipeline doen't contain the read_length attribute
    return true if read_length_list.size == 0

    # There are some requests that don't have the read_length_attribute
    return false if read_length_list.size != batch.requests.size

    (read_length_list.uniq.size == 1)
  end

  def is_flowcell_type_consistent_for_batch?(batch) # rubocop:todo Metrics/AbcSize
    if (batch.requests.size == 0) || batch.requests.first.request_metadata.nil?
      # No requests selected or the pipeline doesn't contain metadata to check
      return true
    end

    flowcell_type_list = batch.requests.filter_map { |request| request.request_metadata.requested_flowcell_type }

    # The pipeline doen't contain the requested_flowcell_type attribute
    return true if flowcell_type_list.size == 0

    # There are some requests that don't have the requested_flowcell_type
    return false if flowcell_type_list.size != batch.requests.size

    (flowcell_type_list.uniq.size == 1)
  end

  # The guys in sequencing want to be able to re-run a request in another batch.  What we've agreed is that
  # the request will be failed and then an identical request will be resubmitted to their inbox.  The
  # "failed" request should not be charged for.
  def detach_request_from_batch(batch, request)
    request.fail!

    # Note that the request metadata also needs to be cloned for this to work.
    ActiveRecord::Base.transaction do
      request.dup.tap do |request_clone|
        rma = request.request_metadata.attributes.merge(request: request_clone)
        request_clone.update!(state: 'pending', target_asset_id: nil, request_metadata_attributes: rma)
        request_clone.comments.create!(
          description:
            # rubocop:todo Layout/LineLength
            "Automatically created clone of request #{request.id} which was removed from Batch #{batch.id} at #{DateTime.now}"
          # rubocop:enable Layout/LineLength
        )
        request.comments.create!(
          description: "The request #{request_clone.id} is an automatically created clone of this one"
        )
      end
    end
  end

  def on_start_batch(batch, user)
    BroadcastEvent::SequencingStart.create!(seed: batch, user: user, properties: {}, created_at: DateTime.now)
  end

  def post_release_batch(batch, _user)
    # We call compact to handle ControlRequests which may have no target asset.
    # In practice this isn't required, as we don't use control lanes any more.
    # However some old feature tests still use them, and until this behaviour is completely
    # deprecated we should leave it here.
    batch.assets.compact.uniq.each(&:index_aliquots)
    Messenger.create!(target: batch, template: 'FlowcellIo', root: 'flowcell')
    # Sends a broadcast message using the 'CommentIo' template to notify the
    # MLWH about under_represented wells associated with the released batch.
    Messenger.create!(target: batch, template: 'CommentIo', root: 'comment')
  end
end
