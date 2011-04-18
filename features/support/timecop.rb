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
