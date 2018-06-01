
class UnrepeatableSequencingPipeline < SequencingPipeline
  def request_actions
    [:fail]
  end
end
