@api @json @tag_layout @single-sign-on @new-api
Feature: Access tag layouts through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual tag layouts through their UUID
  And I want to be able to perform other operations to individual tag layouts
  And I want to be able to do all of this only knowing the UUID of a tag layout
  And I understand I will never be able to delete a tag layout through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario: Reading the JSON for a UUID
    Given the tag layout exists with ID 1
      And the UUID for the tag layout with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout with ID 1 is called "Tag group 1"
      And the UUID for the plate associated with the tag layout with ID 1 is "11111111-2222-3333-4444-000000000001"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "direction": "column",
          "walking_by": "wells in pools",

          "tag_group": {
            "name": "Tag group 1",
            "tags": {
              "1": "ACGT",
              "2": "TGCA"
            }
          },
          "substitutions": { }
        }
      }
      """
