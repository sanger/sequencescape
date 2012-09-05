@external_release
Feature: Display the external release flag for a lane.
  Background:
    Given I am an "administrator" user logged in as "John Smith"

    Scenario: An unknown lane
      Given a lane named "an_unknown_lane" exists
      And I am on the show page for asset "an_unknown_lane"
      Then I should see "Unknown"

    Scenario: A releasable lane
      Given a releasable lane named "a_yes_lane" exists
      And I am on the show page for asset "a_yes_lane"
      Then I should see "Yes"

    Scenario: An unreleasable lane
      Given an unreleasable lane named "a_no_lane" exists
      And I am on the show page for asset "a_no_lane"
      Then I should see "No"


