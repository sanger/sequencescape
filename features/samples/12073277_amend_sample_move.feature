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
    Then show me the page
    Then I should see "Sample has been moved"

