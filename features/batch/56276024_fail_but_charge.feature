Feature: Option to fail but charge requests in a batch
  Background:
    Given I am an "administrator" user logged in as "John Smith"

  Scenario Outline:
    Given user "John Smith" has a workflow "<workflow>"
    And I have a batch with 5 requests for the "<pipeline>" pipeline
    And the batch and all its requests are pending

    Given I am on the "<pipeline>" pipeline page
    When I follow "View pending batch 1"
    Then I should not see "Fail batch or items"
    When the batch is started
    And I follow "<first step>"
    And I follow "Fail batch"
    And I check "Fail request" for 1 to 5
    And I check "Fail but charge"
    And I select "Other" from "Select failure reason"
    And I press "Fail selected requests"
    Then I should see "charged."
    And the customer should accept responsibility for all requests in the last batch

  Scenarios: Library creation pipelines
    | pipeline                          | workflow            | first step  |
    | Illumina-C Library preparation    | Next-gen sequencing | Initial QC  |
    | Illumina-B MX Library Preparation | Next-gen sequencing | Initial QC  |
