@study @javascript @study_listing
Feature: Listing studies by the various possible types
  Background:
    Given I am logged in as "listing_studies_user"
    And I am on the studies page

  Scenario Outline: Listing individual types of studies
    Given a study will appear in the study list "<study type>"
    When I follow "<study type>"
    Then I should see the study for study list "<study type>"

    Examples:
      | study type |
      | Interesting |
      | Followed |
      | Managed & active |
      | Managed & inactive |
      | Pending |
      | Pending ethical approval |
      | Contaminated with human dna |
      | Remove x and autosomes |
      | Active |
      | Inactive |
      | Collaborations |
  #
  # Scenario: Listing all studies
  #   Given studies will appear in the following study lists:
  #     | Interesting |
  #     | Followed |
  #     | Managed & active |
  #     | Managed & inactive |
  #     | Pending |
  #     | Pending ethical approval |
  #     | Contaminated with human dna |
  #     | Active |
  #     | Inactive |
  #     | Collaborations |
  #
  #   When I follow "All"
  #   And the Ajax updates the view
  #
  #   Then I should see the studies for the following study lists:
  #     | Interesting |
  #     | Followed |
  #     | Managed & active |
  #     | Managed & inactive |
  #     | Pending |
  #     | Pending ethical approval |
  #     | Contaminated with human dna |
  #     | Active |
  #     | Inactive |
  #     | Collaborations |
