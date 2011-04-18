Feature: Custom text administration
  Administrators can create, edit, update and delete custom texts

  Background:
    Given all of this is happening at exactly "2010-Oct-03 18:11:17+01:00"

    Given I am a "Manager" user logged in as "xyz1"
    And I have administrative role
    And the following custom texts are defined
      | id | identifier | differential | content_type | content                |
      | 1  | foo        | 99           | letters      | Mary had a little lamb |
      | 2  | bar        | 101          | digits       | 3.1418                 |

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
    When I follow "Edit"
    Then I should see "EDIT CUSTOM TEXT"
    And the field labeled "Custom text identifier" should contain "foo"
    And the field labeled "Custom text differential" should contain "99"
    And the field labeled "Custom text content type" should contain "letters"
    And the field labeled "Custom text content" should contain "Mary had a little lamb"

    # NOTE: Be careful when using symbols as the check is a regexp (i.e. no '?' and '$', unless you escape them!)
    Then I should be able to edit the following fields
      | label        | value   |
      | identifier   | wibble  |
      | differential | 42      |
      | content type | symbols |
      | content      | !$%&@   |

  Scenario: manager adds a new entry
    Given I am on the custom texts admin page
    And I follow "Create custom text"
    Then I should see "CREATE CUSTOM TEXT"

    # NOTE: Be careful when using symbols as the check is a regexp (i.e. no '?' and '$', unless you escape them!)
    Then I should be able to enter the following fields
      | label        | value   |
      | identifier   | wibble  |
      | differential | 42      |
      | content type | symbols |
      | content      | !%@     |
    When I follow "View all custom texts"
    Then I should see "wibble"
    And I should see "foo"
    And I should see "bar"
    When I am editing the custom text field "wibble"
    Then I should see "EDIT CUSTOM TEXT"
    And the field labeled "Custom text content" should contain "!%@"

  Scenario: manager deletes an entry
    Given I am on the custom texts admin page
    And I follow "[Delete]"
    Then I should see "Custom text deleted"
    And the page should contain the following
    | text         |
    | CUSTOM TEXTS |
    | bar          |
    | 101          |
    | digits       |
    | 3.1418       |
    And I should not see "Mary had a little lamb"

  @focus
  Scenario: manager makes data entry errors (model currently does no validations)
    Given I am on the custom texts admin page
    And I follow "Edit"
    Then I should see "EDIT CUSTOM TEXT"
    And the field labeled "Custom text identifier" should contain "foo"
    And the field labeled "Custom text differential" should contain "99"
    And the field labeled "Custom text content type" should contain "letters"
    And the field labeled "Custom text content" should contain "Mary had a little lamb"
    When I fill in the field labeled "Custom text identifier" with ""
    And I fill in the field labeled "Custom text differential" with "wibble"
    And I fill in the field labeled "Custom text content type" with " letters "
    And I fill in the field labeled "Custom text content" with ""
    And I press "Save changes"
    Then I should see "Details have been updated"
    When I follow "Edit"
    Then I should see "EDIT CUSTOM TEXT"
    And the field labeled "Custom text identifier" should contain ""
    And the field labeled "Custom text differential" should contain "0"
    And the field labeled "Custom text content type" should contain " letters "
    And the field labeled "Custom text content" should contain ""

  @xml @api @wip @depricated
  Scenario: manager uses program to make XML requests
    When I request XML from the custom texts admin page
    Then the XML response should be:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <custom-texts type="array">
        <custom-text>
          <id>1</id>
          <content-type>letters</content-type>
          <content>Mary had a little lamb</content>
          <identifier>foo</identifier>
          <differential>99</differential>
          
          <created-at>2010-10-03T18:11:17+01:00</created-at>
          <updated-at>2010-10-03T18:11:17+01:00</updated-at>
        </custom-text>
        <custom-text>
          <id>2</id>
          <content-type>digits</content-type>
          <content>3.1418</content>
          <identifier>bar</identifier>
          <differential>101</differential>

          <created-at>2010-10-03T18:11:17+01:00</created-at>
          <updated-at>2010-10-03T18:11:17+01:00</updated-at>
        </custom-text>
      </custom-texts>
      """

    When I make a request for XML for a custom text identified by "foo"
    Then the XML response should be:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <custom-text>
        <id>1</id>
        <content-type>letters</content-type>
        <content>Mary had a little lamb</content>
        <identifier>foo</identifier>
        <differential>99</differential>

        <created-at>2010-10-03T18:11:17+01:00</created-at>
        <updated-at>2010-10-03T18:11:17+01:00</updated-at>
      </custom-text>
      """

    When I make a request for XML for a custom text identified by "bar"
    Then the XML response should be:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <custom-text>
        <id>2</id>
        <content-type>digits</content-type>
        <content>3.1418</content>
        <identifier>bar</identifier>
        <differential>101</differential>

        <created-at>2010-10-03T18:11:17+01:00</created-at>
        <updated-at>2010-10-03T18:11:17+01:00</updated-at>
      </custom-text>
      """
