class FlexibleCherrypickPipeline < CherrypickForPulldownPipeline
  def post_finish_batch(batch, _user)
    batch.requests.with_target.includes(:request_events).find_each(&:pass!)
  end
end
