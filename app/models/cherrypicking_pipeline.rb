class CherrypickingPipeline < GenotypingPipeline

  def custom_inbox_actions
    [:holder_not_control]
  end

end
