Given /^the submission with UUID "([^\"]+)" has no request types$/ do |uuid|
  resource = Uuid.with_external_id(uuid).first or raise StandardError, "Cannot find submission with UUID #{uuid.inspect}"
  resource.resource.tap do |submission|
    submission.request_types = nil
    submission.save(false)  # This is in complete violation of the laws of nature
  end
end
