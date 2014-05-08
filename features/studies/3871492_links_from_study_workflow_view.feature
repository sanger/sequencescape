@request
Feature: Links from the study workflow page

  Background:
    Given I am logged in as "user"
    Given a reference genome table
      And a study named "Study 3871492" exists
      And the reference genome for study "Study 3871492" is "Schistosoma_mansoni (20100601)"
      And study "Study 3871492" has a registered sample "sample_1-3871492"
      And a library tube named "Asset 1 - 3871492" exists

      And study "Study 3871492" has made the following "Paired end sequencing" requests:
        |  state  | count |       asset       |     sample       |
        | started | none  | Asset 1 - 3871492 | sample_1-3871492 |
        | passed  |   1   | Asset 1 - 3871492 | sample_1-3871492 |
        | failed  |   2   | Asset 1 - 3871492 | sample_1-3871492 |

      And I am on the study workflow page for "Study 3871492"
      And I activate the "Paired end sequencing" tab

  Scenario: The count for started requests is not a link
    Then the started requests for "Asset 1 - 3871492" should not be a link

  @javascript
  Scenario: The count for 1 passed request goes to the request summary page
    When I view the passed requests for "Asset 1 - 3871492"
    Then I should see "This request for paired end sequencing is PASSED"

  @javascript
  Scenario: The count for 2 failed requests goes to the asset overview
    When I view the failed requests for "Asset 1 - 3871492"
    Then I should see "Failed paired end sequencing requests for study 'Study 3871492'"
