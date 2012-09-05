@study @sample @sample_move @asset
Feature: move samples and assets between studies
  Background:
    Given I am an "Administrator" user logged in as "me"
    Given a study called "study to" exists

  Scenario: move a sample without any asset
    Given a study called "study from" exists
    Given I have a sample called "sample_to_move" with metadata
    And the sample "sample_to_move" belongs to the study "study from"
    When I move sample "sample_to_move" from study "study from" to "study to"
    Then I should see "Sample has been moved"
    And the sample "sample_to_move" should belong to the study named "study to"
    And the sample "sample_to_move" should not belong to the study named "study from"

    # check event
    When I am on the events page for sample "sample_to_move"
    Then I should see "is moved from Study"

  Scenario: move a sample with one asset
    Given a study called "study from" exists
    Given study "study from" has the following registered samples in sample tubes with a request:
      | sample | sample tube |
      | sample_to_move | sample_tube_to_move|
    When I move sample "sample_to_move" from study "study from" to "study to"
    Then I should see "Sample has been moved"
    And the sample "sample_to_move" should belong to the study named "study to"
    And the sample "sample_to_move" should not belong to the study named "study from"

    # Checking that the asset has moved
    When I am on the show page for asset "sample_tube_to_move"
    Then I should see "study to"
    And I should not see "study from" within "#requests_table"

    When I am on the events page for asset "sample_tube_to_move"
    Then I should see "is moved from Study"

  Scenario: move a sample with assets from different study
    Given a study called "study from" exists
    Given study "study from" has the following registered samples in sample tubes with a request:
      | sample | sample tube |
      | sample_to_move | sample_tube_to_move|
    Given I have a study called "to_stay study"
    #And  study "to_stay study" has the following samples in sample tubes:
      #| sample | sample tube |
      #| sample_to_move | sample_tube_to_stay|
    Given sample "sample_to_move" is in a sample tube named "sample_tube_to_stay"
    And the sample "sample_to_move" belongs to the study "to_stay study"
    And the asset "sample_tube_to_stay" belongs to study "to_stay study"

    When  I move sample "sample_to_move" from study "study from" to "study to"
    Then I should see "Sample has been moved"
    When I am on the show page for asset "sample_tube_to_move"
    Then I should see "study to"
    And I should not see "study from" within "#requests_table"

    When I am on the show page for asset "sample_tube_to_stay"
    Then I should see "to_stay study"
    And I should not see "study from" within "#requests_table"

  Scenario: move all assets (including tag instance)
    Given a study called "study from" exists
    Given study "study from" has the following registered samples in sample tubes with a request:
      | sample | sample tube |
      | sample_to_move | sample_tube_to_move|
    Given the study "study from" has a library tube called "library_tube_to_move"
    And I have a library tube called "library_tube without study"
    And  the library tube "library_tube_to_move" is a child of the sample tube "sample_tube_to_move"
    And  the library tube "library_tube without study" is a child of the sample tube "sample_tube_to_move"

    When I move sample "sample_to_move" from study "study from" to "study to"
    Then I should see "Sample has been moved"

    # checking that the sample has moved
    Then the sample "sample_to_move" should belong to the study named "study to"
    Then the sample "sample_to_move" should not belong to the study named "study from"

    # Checking that the asset has moved
    When I am on the show page for asset "sample_tube_to_move"
    Then I should see "study to"
    And I should not see "study from" within "#requests_table"

    #checking library tube
    When I am on the show page for asset "library_tube_to_move"
    Then I should see "study to"
    And I should not see "study from" within "#requests_table"

  Scenario: move a sample with one asset to a new asset group
    Given a study called "study from" exists
    Given study "study from" has the following registered samples in sample tubes with a request:
      | sample | sample tube |
      | sample_to_move | sample_tube_to_move|
    When I move sample "sample_to_move" from study "study from" to "study to", to asset group "moved assets" and submission ""
    Then I should see "Sample has been moved"
    And the sample "sample_to_move" should belong to the study named "study to"
    And the sample "sample_to_move" should not belong to the study named "study from"

    # check asset group
    #When I am on the asset group "moved assets" page for study "study to"
    #Then I should see "sample_tube_to_move"

    # Checking that the asset has moved
    When I am on the show page for asset "sample_tube_to_move"
    Then I should see "study to"
    And I should not see "study from" within "#requests_table"

    #Given data are preloaded from "12073277"
  @production_sample @wip @to_fix
  Scenario: move sample in well. example from production
    # real life example which was not working in user story 12073277
    # only a well and plate with create asset request. No submission
    Given data are preloaded from "12073277_sample_in_well" renaming:
      | old name | new name |
      | Study_1700_name | study from |
      | Plate_2383022_name | plate |
      | Sample_1115606_name | sample_to_move |
    When I am on the assets page for the study "study from"
    Then I should see "Plate" within "#assets_with_requests"
    And I should see "Well" within "#assets_with_requests"

    When I move sample "sample_to_move" from study "study from" to "study to"
    When I am on the assets page for the study "study from"
    Then I should not see "Plate" within "#assets"
    And I should not see "Well" within "#assets"

    When I am on the assets page for the study "study to"
    Then I should see "Plate" within "#assets_with_requests"
    And I should see "Well" within "#assets_with_requests"

  Scenario: move sample in well to an asset group
    # sequel of the move sample in well scenario. Same set up , but check asset group
    Given data are preloaded from "12073277_sample_in_well" renaming:
      | old name | new name |
      | Study_1700_name | study from |
      | Plate_2383022_name | plate |
      | Sample_1115606_name | sample_to_move |
    When I move sample "sample_to_move" from study "study from" to "study to", to asset group "moved assets" and submission ""
    When I am on the asset group "moved assets" page for study "study to"
    # so far we only move sample tube.
    And I should not see "Well" within "#assets"
    Then I should not see "Plate" within "#assets"

  @wip
  Scenario: Niel bug
    Given data are preloaded from "RT211312" renaming:
      | old name | new name |
      | Study_1700_name | study from |
      | Study_1787_name | study 17878 to |
      | Sample_1115606_name | sample_to_move |
    When I move samples between studies using the spreadsheet "RT211312_samples_to_move.xls"
    Then the sample "sample_to_move" should belong to the study named "study 17878 to"

  # The aliquot on the lane of a multiplexed library should change study
  Scenario: Niel other bug
    Given data are preloaded from "17802275_move_aliquots" renaming:
      | old_name | new_name |
      | Study_700_name | study_from |
      | Study_605_name | study_to |
      | Sample_1103232_name | sample_to_move |
    When I move samples between studies using the spreadsheet "17802275_samples_to_move.xls"
    Then I should not see "Caution, errors were found"
    Then the sample "sample_to_move" should belong to the study named "study_to"
    And the aliquot 165441 should belong to the study named "study_to"

    # The MultiplexedLibraryTube
    Then all aliquots in asset 2317176 should belong to the study named "study_to"
    # The Lane
    Then all aliquots in asset 2332263 should belong to the study named "study_to"
