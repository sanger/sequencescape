class StripTubeCreationPipeline < Pipeline

  INBOX_PARTIAL = 'group_by_parent'

  def inbox_partial
    INBOX_PARTIAL
  end

  def purpose_information?
    false
  end

end
