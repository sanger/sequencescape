@cherrypicking_for_pulldown @cherrypicking @barcode-service @pulldown @javascript
Feature: Display the errors that occur during cherrypicking for pulldown
  Background:
    Given I am a "administrator" user logged in as "user"
    Given I have a project called "Test project"
    And a robot exists

    Given I have an active study called "Test study"
    And the "96 Well Plate" barcode printer "xyz" exists

  Scenario: There is an asset with no concentration set
    Given plate "1234567" with 1 samples in study "Test study" has a "Cherrypicking for Pulldown" submission for cherrypicking
    Given plate "1234567" has no concentration results

    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    When I check "Select DN1234567T for batch"
    And I press the first "Submit"
    Then I should see "This batch belongs to pipeline: Cherrypicking for Pulldown"
    And I should see "Cherrypick Group By Submission"

    Given a plate barcode webservice is available and returns "99999"

    When I follow "Cherrypick Group By Submission"
    When I fill in "Volume Required" with "13"
    And I fill in "Concentration Required" with "50"
    And I select "Pulldown" from "Plate Purpose"
    And I press "Next step"

    Then I should see "Cherrypick Group By Submission"
    And I should see "Source concentration (nil) is invalid for cherrypick by nano grams per micro litre"

