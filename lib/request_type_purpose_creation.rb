module RequestTypePurposeCreation # rubocop:todo Style/Documentation
  def add_request_purpose
    self.request_purpose = :standard
    self
  end
end
