# frozen_string_literal: true

# This mostly comes from https://github.com/duderman/cucumber_github_formatter
# but we patch puts to ensure we can use it with the progress formatter
module CucumberGithubFormatter::Patch
  def puts(*args)
    super('', *args)
  end
end

# rubocop:disable Style/IfUnlessModifier
unless CucumberGithubFormatter::VERSION == '0.1.0'
  warn "Patching potentially incompatible CucumberGithubFormatter in #{__FILE__}"
end
# rubocop:enable Style/IfUnlessModifier

CucumberGithubFormatter.prepend(CucumberGithubFormatter::Patch)
