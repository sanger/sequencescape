Feature: Show correct volume units

   Background:
      Given I am logged in as "user"
      And I have a sample called "sample_test" with metadata

   Scenario: load sample page and check that the volume units are correct
     Given I am on the show page for sample "sample_test"
     Then I should see "Volume (µl)"
   And I should not see "Volume (&#181;l)"
