
class IlluminaC::AlLibsTaggedPurpose < PlatePurpose
  include PlatePurpose::Initial
  include PlatePurpose::Library

  include PlatePurpose::RequestAttachment

  self.connect_on = 'qc_complete'
  self.connect_downstream = false
end
