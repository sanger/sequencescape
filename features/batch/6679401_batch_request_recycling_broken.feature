@cherrypicking
Feature: Recycling requests in the Cherrypicking pipeline
  Background:
    Given I am an "administrator" user logged in as "John Smith"
    And user "John Smith" has a workflow "Microarray genotyping"

    Given I have a project called "Testing batch request recycling"
    And I have an "active" study called "Testing batch request recycling"

    # All of this to create a batch in the cherrypicking pipeline ...
    Given study "Testing batch request recycling" has an asset group called "My asset group" with 5 wells
    And I have a "Cherrypick" submission with the following setup:
      | Asset Group | My asset group |
      | Project | Testing batch request recycling |
      | Study |     Testing batch request recycling |
    Given 1 pending delayed jobs are processed


    And all assets for requests in the "Cherrypick" pipeline have been scanned into the lab

    Given I am on the "Cherrypick" pipeline page
    When I check "Include request 1"
    And I select "Create Batch" from "Action to perform"
    And I press "Submit"
    And I follow "Start batch"
    And I press "Next"

  # Just to note: the pass/fail/remove requests from batch page that is available for all pipelines is
  # not used in Cherrypicking and therefore we can safely not test this functionality here.  It should
  # be removed from the UI if they aren't using it to prevent them from doing it because the functionality
  # is not the same as moving things from the plate layout.

  @javascript @barcode-service
  Scenario Outline: Approving the plate layout
    Given a robot exists
    Given the plate template "My plate template" exists
    Given a plate barcode webservice is available and returns "1234567"

    Given I am on the "Cherrypick" pipeline page
    When I follow "In progress"
    When I follow "View in progress batch 1"
    And I follow "Select Plate Template"
    And I select "My plate template" from "Plate Template"
    And I press "Next step"

    When I drag <number to remove> wells to the scratch pad
    When I press "Next step"

    # The requests in the Cherrypick inbox are grouped by their parent asset, the plate
    When I am on the "Cherrypick" pipeline page
    Then the inbox should contain 1 request

    # It's not until you choose to create a new batch that you find out how many wells there are!
    When I check "Include request 1"
    And I select "Create Batch" from "Action to perform"
    And I press "Submit"
    Then the batch input asset table should be:
      | Wells              |
      | <number to remove> |

    Examples:
      | number to remove |
      | 5                |
      | 3                |

  @wip
  Scenario: The requests are not in an appropriate state to be recycled
    Given all of the requests in the "Cherrypick" pipeline are in the "blocked" state

    When I check "Remove request 1"
    And I select "Other" from "Select failure reason"
    And I press "Fail items/batch"
    Then I should see "Failed to remove"
