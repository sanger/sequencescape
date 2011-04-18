Feature: Sample registration is tolerant of spreadsheet typos
  Background:
    Given I am an "administrator" user logged in as "John Smith"
    And I have an active study called "Study testing spreadsheet tolerance"

    Given I am on the page for choosing how to register samples for study "Study testing spreadsheet tolerance"
    And I follow "2. Spreadsheet load"

  # NOTE: We use the file, that should be downloaded, directly in this scenario.  Assume they downloaded it ;)
  Scenario: Using the example spreadsheet for download
    Given I am on the page for choosing how to register samples for study "Study testing spreadsheet tolerance"
    When I follow "2. Spreadsheet load"
    And I attach the file "public/data/short_read_sequencing/sample_information.xls" to "File to upload"
    And I press "Upload spreadsheet"
    Then I should not see "Sample sra hold is not included in the list"
