@robot_verification @cherrypick @barcode-service
Feature: Print buffer is required (or not)
  Worksheet in cherrypicking should say if they require buffer to be added

  @javascript
  Scenario: The plates doesn't need any buffer. nothing should be printed
    Given I have a released cherrypicking batch with 1 plate which doesnt need buffer
      And I am on the last batch show page
    When I follow "Print worksheet"
    Then I should see "Destination plate"
      And I should not see "Buffer Required"

  @javascript
  Scenario: One plate needs a buffer. buffer required should be printed
    Given I have a released cherrypicking batch with 1 samples
      And I am on the last batch show page
    When I follow "Print worksheet"
    Then I should see "Destination plate"
      And I should see "Buffer Required"

