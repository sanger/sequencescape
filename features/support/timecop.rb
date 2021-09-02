# frozen_string_literal: true

require 'timecop'

class Timecop # rubocop:todo Style/Documentation
  class << self
    # Block the use of Timecop.freeze as it upsets the Capybara...
    def freeze_with_warning(_time)
      raise <<~EXCEPTION


        #{'*' * 90}

        Timecop.freeze() interferes with Capybara's javascript timeouts.
        Could you either use Timecop.travel instead or not use JavaScript in this scenario?

        #{'*' * 90}

      EXCEPTION
    end
  end
end

# Turning Timecop.freeze off for JavaScript Scenarios
Before('@javascript') do
  class Timecop # rubocop:todo Style/Documentation
    class << self
      alias freeze_without_warning freeze
      alias freeze freeze_with_warning
    end
  end
end
# ...and back on again.
After('@javascript') do
  class Timecop # rubocop:todo Style/Documentation
    class << self
      alias freeze freeze_without_warning
      undef freeze_without_warning
    end
  end
end

After() do |_s|
  # If we're lost in time then we need to return to the present...
  Timecop.return

  # Tell Cucumber to quit after this scenario is done - if it failed.
  # Cucumber.wants_to_quit = true if s.failed?
end
