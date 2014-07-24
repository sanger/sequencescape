class QcPipeline < Pipeline
  INBOX_PARTIAL='show_qc'

  def inbox_partial
    INBOX_PARTIAL
  end

  def qc?
    true
  end
end
