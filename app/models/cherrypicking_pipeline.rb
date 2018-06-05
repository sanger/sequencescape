
class CherrypickingPipeline < GenotypingPipeline
  self.batch_worksheet = 'cherrypick_worksheet'
  self.inbox_eager_loading = :loaded_for_grouped_inbox_display

  def custom_inbox_actions
    [:holder_not_control]
  end

  def robot_verified!(batch)
    batch.requests.each do |request|
      request.reduce_source_volume if request.respond_to?(:reduce_source_volume)
    end
  end
end
