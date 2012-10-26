# To improve the performance of the API we can enable and disable the Ruby garbage collector.  By
# disabling at the start of a request, and re-enabling it after the response has been sent, we can
# reduce the time spent handling a request.
module Core::Service::GarbageCollection
  module Request #:nodoc:
    def instance(action, endpoint)
      Rails.logger.info('API[gc]: disabling GC')
      GC.disable
      super
    end

    def model(action, endpoint)
      Rails.logger.info('API[gc]: disabling GC')
      GC.disable
      super
    end
  end

  module Response #:nodoc:
    def close
      Rails.logger.info('API[gc]: enabling & running GC')

      start = Time.now
      begin
        GC.enable
        GC.start
      ensure
        Rails.logger.info("API[gc]: GC completed in #{Time.now-start}s")
      end
    end
  end
end
