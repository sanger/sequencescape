
class IlluminaC::LibPcrXpPurpose < PlatePurpose
  include PlatePurpose::RequestAttachment

  self.connect_on = 'qc_complete'
  self.connect_downstream = false
end
