@custom_text
Feature: Custom text administration
  Administrators can create, edit, update and delete custom texts

  Background:
    Given all of this is happening at exactly "2010-Oct-03 18:11:17+01:00"

    Given I am a "Manager" user logged in as "xyz1"
    And I have administrative role
    And the following custom texts are defined
      | identifier | differential | content_type | content                |
      | foo        | 99           | letters      | Mary had a little lamb |
      | bar        | 101          | digits       | 3.1418                 |

  Scenario: manager views the list and edits an entry
    Given I am on the custom texts admin page
    Then the page should contain the following
    | text                   |
    | foo                    |
    | bar                    |
    | 99                     |
    | 101                    |
    | letters                |
    | digits                 |
    | Mary had a little lamb |
    | 3.1418                 |
    When I edit the custom text with identifier "foo" and differential "99"
    Then I should see "EDIT CUSTOM TEXT"
    And the field labeled "Custom text identifier" should contain "foo"
    And the field labeled "Custom text differential" should contain "99"
    And the field labeled "Custom text content type" should contain "letters"
    And the field labeled "custom_text[content]" should contain "Mary had a little lamb"

    # NOTE: Be careful when using symbols as the check is a regexp (i.e. no '?' and '$', unless you escape them!)
    Then I should be able to edit the following fields
      | label        | value   |
      | Custom text identifier   | wibble  |
      | Custom text differential | 42      |
      | Custom text content type | symbols |
      | custom_text[content]      | !$%&@   |

  Scenario: manager adds a new entry
    Given I am on the custom texts admin page
    And I follow "Create custom text"
    Then I should see "CREATE CUSTOM TEXT"

    # NOTE: Be careful when using symbols as the check is a regexp (i.e. no '?' and '$', unless you escape them!)
    Then I should be able to enter the following fields
      | label        | value   |
      | Custom text identifier   | wibble  |
      | Custom text differential | 42      |
      | Custom text content type | symbols |
      | custom_text[content]      | !%@     |
    When I follow "View all custom texts"
    Then I should see "wibble"
    And I should see "foo"
    And I should see "bar"
    When I am editing the custom text field "wibble"
    Then I should see "EDIT CUSTOM TEXT"
    And the field labeled "custom_text[content]" should contain "!%@"

  Scenario: manager deletes an entry
    Given I am on the custom texts admin page
    When I delete the custom text with identifier "foo" and differential "99"
    Then I should see "Custom text deleted"
    And the page should contain the following
    | text         |
    | CUSTOM TEXTS |
    | bar          |
    | 101          |
    | digits       |
    | 3.1418       |
    And I should not see "Mary had a little lamb"

  Scenario: manager makes data entry errors (model currently does no validations)
    Given I am on the custom texts admin page
    When I edit the custom text with identifier "foo" and differential "99"
    Then I should see "EDIT CUSTOM TEXT"
    And the field labeled "Custom text identifier" should contain "foo"
    And the field labeled "Custom text differential" should contain "99"
    And the field labeled "Custom text content type" should contain "letters"
    And the field labeled "custom_text[content]" should contain "Mary had a little lamb"
    When I fill in the field labeled "Custom text identifier" with ""
    And I fill in the field labeled "Custom text differential" with "wibble"
    And I fill in the field labeled "Custom text content type" with " letters "
    And I fill in the field labeled "custom_text[content]" with ""
    And I press "Save Custom text"
    Then I should see "Details have been updated"
    When I follow "Edit"
    Then I should see "EDIT CUSTOM TEXT"
    And the field labeled "Custom text identifier" should contain ""
    And the field labeled "Custom text differential" should contain "0"
    And the field labeled "Custom text content type" should contain " letters "
    And the field labeled "custom_text[content]" should contain ""
