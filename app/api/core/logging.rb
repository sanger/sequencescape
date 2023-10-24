# frozen_string_literal: true

module Core::Logging
  def self.logging_helper(name)
    module_eval <<-END_OF_HELPER
      def #{name}(message)
        Rails.logger.#{name}("API(\#{(self.is_a?(Class) ? self : self.class).name}): \#{message}")
      end
    END_OF_HELPER
  end

  %i[debug info error].each { |level| logging_helper(level) }

  def low_level(*args)
    # debug(*args)
  end
end
