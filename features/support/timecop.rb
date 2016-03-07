#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require 'timecop'

class Timecop
  class << self
    # Block the use of Timecop.freeze as it upsets the Capybara...
    def freeze_with_warning(time)
      raise "\n\n#{'*'*90}\nTimecop.freeze() interferes with Capybara's javascript timeouts.\nCould you either use Timecop.travel instead or not use JavaScript in this scenario?  \n\n#{'*'*90}\n\n"
    end
  end
end

# Turning Timecop.freeze off for JavaScript Scenarios
Before('@javascript') do
  class Timecop
    class << self
      alias_method_chain :freeze, :warning
    end
  end
end
# ...and back on again.
After('@javascript') do
  class Timecop
    class << self
      alias_method :freeze, :freeze_without_warning
      undef :freeze_without_warning
    end
  end
end

After do |s|
  # If we're lost in time then we need to return to the present...
  Timecop.return

  # Tell Cucumber to quit after this scenario is done - if it failed.
  # Cucumber.wants_to_quit = true if s.failed?
end
