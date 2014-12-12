class IlluminaHtp::NormalizedPlatePurpose < PlatePurpose
  include PlatePurpose::RequestAttachment

  write_inheritable_attribute :connect_on, 'passed'
  write_inheritable_attribute :connect_downstream, false
  write_inheritable_attribute :connected_class, IlluminaHtp::Requests::LibraryCompletion

end
