Given /^all the "([^"]*)" requests in the last submission have been started$/ do |request_type|
  Submission.last.requests.select{|r| r.sti_type == request_type}.map(&:start!)
end
