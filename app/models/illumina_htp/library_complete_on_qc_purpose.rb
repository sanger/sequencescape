class IlluminaHtp::LibraryCompleteOnQcPurpose < PlatePurpose

  include PlatePurpose::RequestAttachment
  include PlatePurpose::BroadcastLibraryComplete

  self.connect_on = 'qc_complete'
  self.connect_downstream = false
  self.connected_class = IlluminaHtp::Requests::StdLibraryRequest

end
