# frozen_string_literal: true
module RequestTypePurposeCreation
  def add_request_purpose
    self.request_purpose = :standard
    self
  end
end
