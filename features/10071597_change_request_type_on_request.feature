@request
Feature: if request is pending then the admin could change of request type.
  Background:
     Given I am logged in as "John Smith"
     And I am an administrator
     And sequencescape is setup for 10071597

   Scenario: The request is not pending. We should not see Request Type combo.
     Given last request the state "started"
     Given I am on the page for editing the last request
     Then I should not see "Request Type:"

   Scenario: Request is pending. I should see combobox Request Type. No change. it should work properly
     Given I am on the page for editing the last request
     Then I should see "Request Type:"
     And I press "Save Request"
     Then I should see "Request details have been updated"

   Scenario: The user asks to change with Request Type
     Given I am on the page for editing the last request
     Then I should see "Request Type:"
     When I select "Single ended sequencing" from "Request Type:"
     And I press "Save Request"
     Then I should see "Request details have been updated"

