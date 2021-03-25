# Superclass for all Cherrypicking pipelines. Not used directly
class CherrypickingPipeline < GenotypingPipeline
  PICKED_STATES = %w[completed released].freeze

  self.batch_worksheet = 'cherrypick_worksheet'
  self.inbox_eager_loading = :loaded_for_grouped_inbox_display
  self.asset_type = 'Well'
  self.pick_data = true

  def robot_verified!(batch)
    batch.requests.each do |request|
      request.reduce_source_volume if request.respond_to?(:reduce_source_volume)
    end
  end

  def pick_information?(batch)
    PICKED_STATES.include?(batch.state)
  end

  def update_detached_request(batch, request)
    batch.remove_link(request)
  end
end
