class PulldownLibraryCreationPipeline < LibraryCreationPipeline
  def pulldown?
    true
  end

  def prints_a_worksheet_per_task?
    true
  end
end
