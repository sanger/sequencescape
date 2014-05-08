@javascript @pipeline
Feature: Order a table with tablesorter plugin.
  Background:
    Given I am logged in as "John Smith"
    And I am an administrator

    Scenario: Order the table clicking "Name" column
      Given I have five requests for "Illumina-C Library preparation"
      Given I am on the "Illumina-C Library preparation" pipeline page
      When I follow "Name"
      Then the table of requests should be:
        | Name         |
        | Test Asset 0 |
        | Test Asset 1 |
        | Test Asset 2 |
        | Test Asset 3 |
        | Test Asset 4 |
      When I follow "Name"
      Then the table of requests should be:
        | Name         |
        | Test Asset 4 |
        | Test Asset 3 |
        | Test Asset 2 |
        | Test Asset 1 |
        | Test Asset 0 |