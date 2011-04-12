@study @sample @sample_move @asset
Feature: move samples and assets between studies
  Background:
    Given I am an "Administrator" user logged in as "me"
    Given a study called "study from" exists
    Given a study called "study to" exists

  Scenario: move a sample without any asset
    Given I have a sample called "sample_to_move" with metadata
    And the sample "sample_to_move" belongs to the study "study from"
    When I move sample "sample_to_move" from study "study from" to "study to"
    Then I should see "Sample has been moved"
    And the sample "sample_to_move" should belong to the study named "study to"
    And the sample "sample_to_move" should not belong to the study named "study from"

  Scenario: move a sample with one asset
    Given study "study from" has the following registered samples in sample tubes:
      | sample | sample tube |
      | sample_to_move | sample_tube_to_move|
    When I move sample "sample_to_move" from study "study from" to "study to"
    Then I should see "Sample has been moved"
    And the sample "sample_to_move" should belong to the study named "study to"
    And the sample "sample_to_move" should not belong to the study named "study from"

    # Checking that the asset has moved
    When I am on the show page for asset "sample_tube_to_move"
    Then I should see "study to"
    And I should not see "study from"

  Scenario: move a sample with assets from different study
    Given study "study from" has the following registered samples in sample tubes:
      | sample | sample tube |
      | sample_to_move | sample_tube_to_move|
    Given I have a study called "to_stay study"
    And  study "to_stay study" has the following samples in sample tubes:
      | sample | sample tube |
      | sample_to_move | sample_tube_to_stay|
    Given sample "sample_to_move" is in a sample tube named "sample_tube_to_stay"
    And the sample "sample_to_move" belongs to the study "to_stay study"
    And the asset "sample_tube_to_stay" belongs to study "to_stay study"

    When  I move sample "sample_to_move" from study "study from" to "study to"
    Then I should see "Sample has been moved"
    When I am on the show page for asset "sample_tube_to_move"
    Then I should see "study to"
    And I should not see "study from"

    When I am on the show page for asset "sample_tube_to_stay"
    Then I should see "other study"
    And I should not see "study from"

  Scenario: move all assets (including tag instance)
    Given study "study from" has the following registered samples in sample tubes:
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
    And I should not see "study from"

    #checking library tube
    When I am on the show page for asset "library_tube_to_move"
    Then I should see "study to"
    And I should not see "study from"
