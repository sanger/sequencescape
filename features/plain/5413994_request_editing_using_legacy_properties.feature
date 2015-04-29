# rake features FEATURE=features/plain/5413994_request_editing_using_legacy_properties.feature
@request @metadata @ci_fail
Feature: Editing a request as an administrator
  Background:
    Given I am an "administrator" user logged in as "John Smith"

    Given I have an active study called "Testing editing a request"
    And I have a library tube of stuff called "tube_1"
    And I have already made a request for library tube "tube_1" within the study "Testing editing a request"

  Scenario: Editing a request
    Given I am on the page for editing the last request

    When I select "Standard" from "Library type"
    And I fill in "Fragment size required (from)" with "11111111"
    And I fill in "Fragment size required (to)" with "22222222"
    And I fill in "Read length" with "76"
    And I fill in "Gigabases expected" with "1"
    And I press "Save changes"
    Then I should see "Request details have been updated"
    And I should see the following request information:
      | Still charge on fail:          | Not specified |
      | Read length:                   | 76            |
      | Gigabases expected:            | 1.0           |
      | Fragment size required (from): | 11111111      |
      | Fragment size required (to):   | 22222222      |
      | Library type:                  | Standard      |

