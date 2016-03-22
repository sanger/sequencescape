@pipeline
Feature: Create a new pipeline called Cluster Formation SE (no controls)
     Create a batch for this pipeline

  Background:
    Given I am a "administrator" user logged in as "John Smith"

  Scenario: I make a batch for SE no controls pipeline
    Given Pipeline "Cluster formation SE (no controls)" and a setup for 641709
      And I am on the show page for pipeline "Cluster formation SE (no controls)"

    Then I should be on the "Cluster formation SE (no controls)" pipeline page
      When I select eight requests
      And I select "Create Batch" from the first "Action to perform"
      And I press the first "Submit"
      Then I should see "Specify Dilution Volume"
