Feature: Illumina C muliplex inbox feature
  As a Lab manager I want to be able to view Illumina C multiplex library creation requests.

  Scenario: New Illumina C multiplex library requests should appear in the corresponding inbox.
    Given that there is a "Illumina-C MX Library Preparation" pipeline
    And that there are 7 requests in that pipeline
    And I am an "lab manager" user logged in as "John Smith"
    And I go to the "Illumina-C MX Library Preparation" pipeline page
    And I should see "Illumina-C MX Library Preparation"
    Then we see the requests in the inbox
