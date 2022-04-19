@api @json @tag2_layout_template @single-sign-on @new-api
Feature: Access tag 2 layout templates through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual index tag layout templates through their UUID
  And I want to be able to perform other operations to individual index tag layout templates
  And I want to be able to do all of this only knowing the UUID of a index tag layout template
  And I understand I will never be able to delete a index tag layout template through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"

    Given the tag 2 layout template "Test tag layout" exists
    And the UUID for the tag 2 layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"

  @read
  Scenario: Reading the JSON for a UUID

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag2_layout_template": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Test tag layout",

          "tag": {
            "name": "Tag 1",
            "oligo": "AAA"
          }
        }
      }
      """

  @tag_layout @create @barcode-service
  Scenario: Creating a tag layout from a tag 2 layout template
    Given the plate barcode webservice returns "SQPD-1000001"

    Given the UUID of the next tag 2 layout created will be "00000000-1111-2222-3333-000000000002"

    Given a "Stock plate" plate called "Testing the tagging" exists
      And the UUID for the plate "Testing the tagging" is "11111111-2222-3333-4444-000000000001"
      And all wells on the plate "Testing the tagging" have unique samples

    Given a "Tag 2 Tube" tube called "test tube" exists
     And the UUID for the last tube is "11111111-2222-3333-4444-900000000001"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "tag2_layout": {
          "source": "11111111-2222-3333-4444-900000000001",
          "plate":  "11111111-2222-3333-4444-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag2_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            }
          },
          "source": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-900000000001"
            }
          },

          "uuid": "00000000-1111-2222-3333-000000000002",

          "tag": {
            "name": "Tag 1",
            "oligo": "AAA"
          }
        }
      }
      """

    Then the tag 2 layout on the plate "Testing the tagging" should be:
      | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA |
      | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA |
      | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA |
      | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA |
      | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA |
      | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA |
      | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA |
      | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA | AAA |
