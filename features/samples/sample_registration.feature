@sample @registration
Feature: Registering samples
  # TODO: All of these scenarios, except for the spreadsheet ones, only register 1 sample because the page requires Javascript.

  Background:
    Given I am an "external" user logged in as "John Smith"
    And I have an active study called "Testing registering samples"
    And user "John Smith" is a "manager" of study "Testing registering samples"

    Given I am on the page for choosing how to register samples for study "Testing registering samples"
    And I follow "1. Manual entry"

  Scenario: The required fields are required
    Then I should see the text field "Sample name for sample 0"
    And I should see "Donor Id"

    When I press "Register samples"
    Then I should be on the sample error page for study "Testing registering samples"
    And I should see "Your samples have not been registered"
    And I should see "Sample name can't be blank"

  Scenario: Registering a single sample
    When I fill in "Sample name for sample 0" with "sample_name_for_0"
    And I press "Register samples"
    Then I should be on the study workflow page for "Testing registering samples"
    And I should see "Your samples have been registered"

  Scenario: Registering a sample that already exists
    Given the sample named "sample_already_exists" exists
    When I fill in "Sample name for sample 0" with "sample_already_exists"
    And I press "Register samples"
    Then I should be on the sample error page for study "Testing registering samples"
    And I should see "Sample name already in use"

  Scenario: Registering a sample with a new asset group
    When I fill in "Sample name for sample 0" with "sample_for_asset_group"
    And I fill in "Asset group name for sample 0" with "asset_group_for_sample"
    And I press "Register samples"
    Then I should be on the study workflow page for "Testing registering samples"

    When I follow "Asset groups"
    And I follow "asset_group_for_sample"
    Then I should see "sample_for_asset_group"

  Scenario: Asset group has whitespace before and or after name
    When I fill in "Sample name for sample 0" with "sample_for_asset_group"
    And I fill in "Asset group name for sample 0" with " asset_group_for_sample"
    And I press "Register samples"
    Then I should be on the study workflow page for "Testing registering samples"

    When I follow "Asset groups"
    And I follow "asset_group_for_sample"
    Then I should see "sample_for_asset_group"

  # NOTE: The behaviour here is slightly different to what the browser will do if you ignore a sample.
  # The browser has it's fields disabled and should be prevented from sending those fields in the
  # request.  However, webrat doesn't execute the Javascript so it does send the fields but includes
  # the ignore value so the controller has to handle this.
  Scenario: Attempting to register an ignored sample
    When I fill in "Sample name for sample 0" with "sample_name_for_0"
    And I check "Ignore sample 0"
    And I press "Register samples"
    Then I should be on the sample error page for study "Testing registering samples"
    And I should see "You do not appear to have specified any samples"
    And I should see the text field "Sample name for sample 0"

  Scenario: Invalid sample name with an asset group, does not error when resending
    When I fill in "Asset group name" with "Does not exist group"
    And I press "Register samples"
    Then I should be on the sample error page for study "Testing registering samples"
    And I should see "Your samples have not been registered"
    And I should see "Sample name can't be blank"
    And the "Sample name for sample 0" field should be marked in error

    When I fill in "Sample name for sample 0" with "sample_name_for_0"
    And I fill in "Asset group name" with "Does not exist group"
    And I press "Register samples"
    Then I should be on the study workflow page for "Testing registering samples"
    And I should see "Your samples have been registered"

  Scenario: Fields filled with data should remain so after invalid submission
    When I fill in "2D barcode for sample 0" with "12345"
    And I fill in "Organism for sample 0" with "Weird green jelly like thing"
    And I press "Register samples"
    Then I should be on the sample error page for study "Testing registering samples"
    And I should see "Your samples have not been registered"
    And I should see "Sample name can't be blank"
    And the "2D barcode for sample 0" field should contain "12345"
    And the "Organism for sample 0" field should contain "Weird green jelly like thing"

  @sample_registration
   Scenario: Uploading a spreadsheet of data for sequencing
    Given user "John Smith" has a workflow "Next-gen sequencing"

    Given I am on the page for choosing how to register samples for study "Testing registering samples"
    And I follow "2. Spreadsheet load"
    Then I should see "Please select a spreadsheet to upload"

    When I attach the relative file "test/data/sample_info_valid.xls" to "File to upload"
    And I press "Upload spreadsheet"
    Then I should be on the spreadsheet sample registration page for study "Testing registering samples"
    And the following samples should be in the sample registration fields:
      |Sample name           |Cohort|Country of origin|Geographical region|Gender|Volume (µl)| Ethnicity | DNA source | Donor Id |
      |cn_dev_96_inc_blank_01|ro    |uk               |europe             |Male  |100        | Caucasian | Blood      | 12345    |
      |cn_dev_96_inc_blank_02|ro    |uk               |europe             |Female|100        | Caucasian | Blood      | 12345    |
      |cn_dev_96_inc_blank_03|ro    |uk               |europe             |Male  |100        | Caucasian | Blood      | 12345    |
      |cn_dev_96_inc_blank_04|ro    |uk               |europe             |Female|100        | Caucasian | Blood      | 12345    |
    And every sample in study "Testing registering samples" should be accessible via a request

  Scenario: Uploading a non-spreadsheet file
    Given I am on the page for choosing how to register samples for study "Testing registering samples"
    And I follow "2. Spreadsheet load"
    When I attach the relative file "features/samples/sample_registration.feature" to "File to upload"
    And I press "Upload spreadsheet"
    Then I should see "Problems processing your file. Only Excel spreadsheets accepted"
