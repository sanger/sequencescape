#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
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
