@hiseq @request @library_tube @javascript
Feature: Requesting additional HiSeq sequencing for a library tube
  Background:
    Given I am an "administrator" user logged in as "John Smith"

    Given I have a project called "Testing HiSeq Project"

    Given I have an active study called "Testing HiSeq Study"
    And I have a library tube of stuff called "tube_1"
    And I have already made a request for library tube "tube_1" within the study "Testing HiSeq Study"

  Scenario: Requesting an additional HiSeq sequencing
    Given I am on the show page for library tube "tube_1"
    When I follow "Request additional sequencing"
    And I select "Illumina-B HiSeq Paired end sequencing" from "Request type"
    And I select "Testing HiSeq Study" from "Study"
    And I select "Testing HiSeq Project" from "Project"
    #And I select "Standard" from "Library type"
    And I select "50" from "Read length" for the "Illumina-B HiSeq Paired end sequencing" request type
    And I fill in "Fragment size required (from)" with "11111111" for the "Illumina-B HiSeq Paired end sequencing" request type
    And I fill in "Fragment size required (to)" with "22222222" for the "Illumina-B HiSeq Paired end sequencing" request type
    And I fill in "Comments" with "Please do this otherwise I'll be upset"
    And I press "Create"
    Then I should see "Created request"

    Given all pending delayed jobs are processed

    Given I am on the show page for library tube "tube_1"
    When I follow the "HiSeq Paired end sequencing" request
    #Then I should see "Library type" set to "Standard"
    And I should see "Read length" set to "50"
    And I should see "Fragment size required (from)" set to "11111111"
    And I should see "Fragment size required (to)" set to "22222222"


