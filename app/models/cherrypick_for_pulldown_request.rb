class CherrypickForPulldownRequest < TransferRequest


  def perform_transfer_of_contents
    on_started # Ensures we set the study/project
  end
  private :perform_transfer_of_contents

end
