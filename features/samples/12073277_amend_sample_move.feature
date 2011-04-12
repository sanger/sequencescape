@study @sample @sample_move @asset
Feature: move samples and assets between studies
  Background:
    Given I am an "Administrator" user logged in as "me"
    Given a study called "study from" exists
    Given a study called "study to" exists

  Scenario: move a sample with one asset
    Given study "study from" has the following registered samples in sample tubes:
      | sample | sample tube |
      | Sample_1 | Sample_Tube_1|
    When I move sample "Sample_1" from study "study from" to "study to"
    Then I should see "Sample has been moved"

    # checking that the sample has moved
    When I am on the show page for sample "Sample_1"
    Then I should see "study to"
    And I should not see "studo from"

    # Checking that the asset has moved
    When I am on the show page for asset "Sample_Tube_1"
    Then I should see "study to"
    And I should not see "studo from"
  Scenario: move a sample with assets from different study
    Given study "study from" has the following registered samples in sample tubes:
      | sample | sample tube |
      | Sample_1 | Sample_Tube_1|
    Given I have a study called "other study"
    And  study "other study" has the following samples in sample tubes:
      | sample | sample tube |
      | Sample_1 | Sample_Tube_other|
    #Given sample "Sample_1" is in a sample tube named "Sample_Tube_other"
    #And the sample "Sample_1" belongs to the study "other study"
    #And the asset "Sample_Tube_other" belongs to study "other study"

    Then I move sample "Sample_1" from study "study from" to "study to"
    Then I should see "Sample has been moved"
    When I am on the show page for asset "Sample_Tube_1"
    Then I should see "study to"
    And I should not see "studo from"

    When I am on the show page for asset "Sample_Tube_other"
    Then I should see "study other"
    And I should not see "studo from"
