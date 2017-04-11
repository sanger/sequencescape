namespace :requests do
  desc 'Tests requests statuses before implementing aasm and migrating data. Should disable aasm in Request before running this task'
  task test: :environment do
    Request.all.each do |request|
      case request.current_status
      when 'Complete'
        if request.complete?
          # puts "COMPLETE => @request.current_status is  COMPLETE"
        else
          puts "# COMPLETE => complete value: #{request.complete}, request ID: #{request.id}"
          puts '    ------------------------------------------------------'
        end
      when 'Failed'
        if request.fail?
          # puts "FAILED => @request.fail is FAILED"
        else
          puts "# FAILED => fail value: #{request.fail}, request ID: #{request.id}"
          puts '    ------------------------------------------------------'
        end
      when 'Pending'
        if request.fail? && request.complete?
          puts "# PENDING => fail value: #{request.fail}, complete value: #{request.complete}, request ID: #{request.id}"
          puts '    ------------------------------------------------------'
        end
      end
    end
  end
end
