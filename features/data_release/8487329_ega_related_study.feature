@study @ega @related_studies
Feature: A user should be able to relate studies
  Background:
    Given I am logged in as "me"
    Given I have a study called "master"
    And user "me" is an "manager" of study "master"
    Given I have a study called "slave"
    And user "me" is a "follower" of study "slave"

  Scenario: only a manager can manage relation
    Given I am on the related studies page for study "slave"
    Then I should not see "Add a study relation"

  Scenario: A manager assign a study relation
    Given I am on the related studies page for study "master"
    Then I should see "Add a study relation"
    When I select "slave" from "Select a study"
    And I select "test" from "related_study_relation_type"
    And I press "Add related study"
    Then I should see "test" within "div#related_studies"
    Then I should see "Slave" within "div#related_studies"

  Scenario: A manager delete a study relation
    Given the study "slave" is "test" of study "master"
    Given I am on the related studies page for study "master"
    And I should see "Slave" within "div#related_studies"
    When I press "Remove"
    Then I should not see "Slave" within "div#related_studies"

  Scenario: a lambda user fail to delete a study relation
    Given the study "slave" is "test" of study "master"
    Given I am logged in as "another user"
    When I am on the related studies page for study "master"
    Then I should not see "Related studies"
