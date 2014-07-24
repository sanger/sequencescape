@submission @new_submission @wip
Feature: Submission and Order Creation
  As a Project Manager I want to be able to create a submission from a Study, a Project and some Assets,
  adding orders to the Submission before submitting it.

  Background:
    Given I am an "administrator" user logged in as "John Smith"
    And I am on the Submissions Inbox page


  Scenario: Building a Submission without any orders from scratch
    Given I follow "new Submission"
      And I find a Project using a few characters of the Financial Project Name
      And I find a Study using a few character of the Study Name
      And I select the first template from the template list
    Then I am presented with the Templates submission requirements
    Given I then agree to the Submission Requirements
      And I set the correct Submission Parameters for the template
    Then I am ready to add Orders to the Project

  # Scenario: Finishing an already started Submission
