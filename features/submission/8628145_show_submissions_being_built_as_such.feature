@submission
Feature: Status of the submissions should be displayed correctly to the user
  Background:
    Given I am an "administrator" user logged in as "John Smith"

    Given I have an active study called "Testing submission statuses"

  Scenario Outline: Displaying the submissions status
    Given I have a submission in the "<state>" state
    When I am on the show page for the last submission
    Then I should see "<message>"

    Examples:
      | state      | message                                                                                             |
      | building   | This submission is still open for editing, further orders can still be added...                     |
      | pending    | Your submission is currently pending                                                                |
      | processing | Your submission is currently being processed                                                        |
      | ready      | Your submission has been processed                                                                  |
      # | unknown    | Your submission is in an unknown state (contact support)                                            |/

  Scenario: Submission has failed so the message should be displayed
    Given I have a submission in the "failed" state with message "Sorry, but it's broken"
    When I am on the show page for the last submission
    Then I should see "Your submission has failed"
    And I should see "Sorry, but it's broken"
