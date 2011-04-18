
print "Submission ID? : "
submission_id = gets.chomp

Request.find_all_by_submission_id(submission_id).each do |request|
  if request.request_type.id == 8 
    raise "request problem #{request.id}" if request.asset.nil?
    request.set_state("pending")
  end
  if request.request_type.id == 6
    puts "#{request.asset.plate.barcode}"
    request.set_state("passed")
  end
end



