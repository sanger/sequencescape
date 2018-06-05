class IlluminaHtp::LibraryCompleteOnQcPurpose < PlatePurpose
  include PlatePurpose::Library
  include PlatePurpose::RequestAttachment
  include PlatePurpose::BroadcastLibraryComplete

  self.connect_on = 'qc_complete'
  self.connect_downstream = false
end
