@barcode-service @pipeline @inbox
Feature: Requests should disappear from the inbox when a batch is started

  Background:
    Given I am an "manager" user logged in as "john"

  Scenario: Requests should disappear from inbox after batch started
    Given a plate barcode webservice is available and returns "99999"
    Given I have a plate "222" with the following wells:
      | well_location | measured_concentration | measured_volume |
      | B2            | 120                    |                 |
    Given I have a "Cherrypicking for Pulldown" submission with plate "222"
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    And I check "Select DN222J for batch"
    And I select "Create Batch" from the first "Action to perform"
    And I press the first "Submit"
    When I follow "Cherrypick Group By Submission"
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    Then I should not see "222"

