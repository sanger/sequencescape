# frozen_string_literal: true

# Will construct plates with well_count wells filled with samples
class UatActions::IntegrationSuiteTools < UatActions
  self.title = 'Integration suite tools'

  # The description displays on the list of UAT actions to provide additional information
  self.description =
    # rubocop:todo Layout/LineLength
    'Returns a suite of information for configuring automatic integration tests. Of limited use in UAT but will not cause problems.'

  # rubocop:enable Layout/LineLength

  # Form fields
  # We don't actually have any fields

  def self.default
    new
  end

  #
  # Generates static records, and returns useful information about them
  #
  # @return [true] The records have been found or created. Under normal circumstances this action should never fail
  def perform
    report[:user_login] = user.login
    report[:user_swipecard] = UatActions::StaticRecords::SWIPECARD_CODE
    true
  end

  private

  # Any helper methods

  def user
    UatActions::StaticRecords.user
  end
end
