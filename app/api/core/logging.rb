module Core::Logging
  def self.logging_helper(name)
    module_eval <<-END_OF_HELPER
      def #{name}(message)
        Rails.logger.#{name}("API(\#{(self.is_a?(Class) ? self : self.class).name}): \#{message}")
      end
    END_OF_HELPER
  end

  [ :debug, :info, :error ].each do |level|
    logging_helper(level)
  end

  def low_level(*args)
    #debug(*args)
  end
end
