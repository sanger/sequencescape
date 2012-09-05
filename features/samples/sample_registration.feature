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

    When I press "Register samples"
    Then I should be on the sample error page for study "Testing registering samples"
    And I should see "Your samples have not been registered"
    And I should see "Name can't be blank"

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
    And I should see "Name already in use"

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
    And I should see "Name can't be blank"
    And the "Sample name for sample 0" field should be marked in error

    When I fill in "Sample name for sample 0" with "sample_name_for_0"
    And I fill in "Asset group name" with "Does not exist group"
    And I press "Register samples"
    Then I should be on the study workflow page for "Testing registering samples"
    And I should see "Your samples have been registered"

  # TODO: Really this should have steps like 'Then the sample registration row for "Sample 1" should not exist'
  # And check that all the values are reset to the blank state.
  # TODO: 'Add row' should be a button!
  @wip @javascript
  Scenario: Adding new rows
    Then I should not see the text field "Common name for sample 1"
    And I should not see the text field "Common name for sample 2"

    When I follow "Add row"
    Then I should see the text field "Common name for sample 1"

    When I follow "Add row"
    Then I should see the text field "Common name for sample 2"

  @wip @javascript
  Scenario: Adding a new row if the first row is ignored
    Given I check "Ignore sample 0"
    When I follow "Add row"
    Then the "Ignore sample 1" checkbox should be checked

  @wip @javascript
  Scenario: Looking up the real 'common name' and 'taxon ID' for multiple samples
    When I fill in "Common name for sample 0" with "human"
    And I press "Lookup"

    Then the "Common name for sample 0" field should contain "Homo sapiens"
    And the "Taxon ID for sample 0" field should contain "9606"

  @wip @javascript
  Scenario: Looking up the real 'common name' and 'taxon ID' when they error
    When I fill in "Common name for sample 0" with "horrible looking green slime"
    And I press "Lookup"

    Then the "Common name for sample 0" field should be marked in error
    And the "Taxon ID for sample 0" field should be marked in error

  @wip @javascript
  Scenario: Lookup up the real 'common name' and 'taxon ID' for multiple samples
    When I fill in "Common name for sample 0" with "human"
    And I fill in "Common name for sample 1" with "rat"
    And I fill in "Common name for sample 2" with "mouse"
    And I press "Lookup"

    Then the "Common name for sample 0" field should contain "Homo sapiens"
    And the "Taxon ID for sample 0" field should contain "9606"
    And the "Common name for sample 1" field should contain "Rattus norvegicus"
    And the "Taxon ID for sample 1" field should contain "10116"
    And the "Common name for sample 2" field should contain "Mus musculus"
    And the "Taxon ID for sample 2" field should contain "10090"

  # TODO: Implement the following scenario
  # In theory this should behave much like the one with an asset group except that when
  # you check for the asset it does not exist, which is kind of worrying.
  @wip
  Scenario: Setting a 2D barcode on the sample, with no asset group

    @wip @to_fix
  Scenario: Setting a 2D barcode on the sample which goes into an asset group
    When I fill in "Sample name for sample 0" with "sample_with_barcode"
    And I fill in "2D barcode for sample 0" with "12345"
    And I fill in "Asset group name" with "Barcoded assets"
    And I press "Register samples"
    Then I should be on the study workflow page for "Testing registering samples"
    And I should see "Your samples have been registered"

    When I follow "Assets"
    And I follow "sample_with_barcode"
    Then I should see "NT345B"

  Scenario: Fields filled with data should remain so after invalid submission
    When I fill in "2D barcode for sample 0" with "12345"
    And I fill in "Organism for sample 0" with "Weird green jelly like thing"
    And I press "Register samples"
    Then I should be on the sample error page for study "Testing registering samples"
    And I should see "Your samples have not been registered"
    And I should see "Name can't be blank"
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
    Then I should be on the sample registration page for study "Testing registering samples"
    And the following samples should be in the sample registration fields:
      |Sample name           |Cohort|Country of origin|Geographical region|Gender|Volume (µl)| Ethnicity | DNA source |
      |cn_dev_96_inc_blank_01|ro    |uk               |europe             |Male  |100        | Caucasian | Blood      |
      |cn_dev_96_inc_blank_02|ro    |uk               |europe             |Female|100        | Caucasian | Blood      |
      |cn_dev_96_inc_blank_03|ro    |uk               |europe             |Male  |100        | Caucasian | Blood      |
      |cn_dev_96_inc_blank_04|ro    |uk               |europe             |Female|100        | Caucasian | Blood      |
    And every sample in study "Testing registering samples" should be accessible via a request

  Scenario: Uploading a non-spreadsheet file
    Given I am on the page for choosing how to register samples for study "Testing registering samples"
    And I follow "2. Spreadsheet load"
    When I attach the relative file "features/samples/sample_registration.feature" to "File to upload"
    And I press "Upload spreadsheet"
    Then I should see "Problems processing your file. Only Excel spreadsheets accepted"
