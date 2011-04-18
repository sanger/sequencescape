module DelayedJobEx
  def send_later_with_priority(priority, method, *args)
   job = Delayed::PerformableMethod.new(self, method, args)
   Delayed::Job.enqueue(job, priority)
  end
end
