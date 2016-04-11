@api @json @single-sign-on @new-api @barcode-service
Feature: Access volume updates through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create individual volume updates through their plate UUID
  And I understand I will never be able to delete a volume update through its UUID
  And I understand I will never be able to update a volume update through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given a plate called "Plate 1" with ID 1
      And the plate "Plate 1" has a barcode of "1220000333802"
      And the UUID for the plate "Plate 1" is "11111111-2222-3333-4444-000000000003"
      And I have a plate with uuid "11111111-2222-3333-4444-000000000003" with the following wells:
       | well_location | measured_concentration | measured_volume |
       | B1            | 100                    | 20              |
       | B2            | 120                    | 10              |
       | B3            | 140                    | 20              |
       | B4            | 160                    | 20              |
       | B5            | 180                    | 20              |
       | B6            | 200                    | 20              |

  Scenario: Creating volume updates on a plate

    Given the UUID of the next volume update created will be "11111111-2222-3333-4444-000000000001"
    When I make an authorised POST with the following JSON to the API path "/11111111-2222-3333-4444-000000000003/volume_updates":
      """
      {
        "volume_update": {
          "user": "99999999-8888-7777-6666-555555555555",
          "volume_change": "24.3"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "volume_update":{
          "target":{ "uuid":"11111111-2222-3333-4444-000000000003" },
          "user":{   "uuid":"99999999-8888-7777-6666-555555555555" },
          "actions":{
            "read":"http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
          },
          "uuid":"11111111-2222-3333-4444-000000000001",
          "volume_change": 24.3
        }
      }
      """
      Then I should have a plate with uuid "11111111-2222-3333-4444-000000000003" with the following wells volumes:
       | well_location | current_volume  |
       | B1            | 44.3              |
       | B2            | 34.3              |
       | B3            | 44.3              |
       | B4            | 44.3              |
       | B5            | 44.3              |
       | B6            | 44.3              |

    Given the UUID of the next volume update created will be "11111111-2222-3333-4444-000000000002"
    When I make an authorised POST with the following JSON to the API path "/11111111-2222-3333-4444-000000000003/volume_updates":
      """
      {
        "volume_update": {
          "user": "99999999-8888-7777-6666-555555555555",
          "volume_change": "-7.1"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "volume_update":{
          "target":{ "uuid":"11111111-2222-3333-4444-000000000003" },
          "user":{   "uuid":"99999999-8888-7777-6666-555555555555" },
          "actions":{
            "read":"http://www.example.com/api/1/11111111-2222-3333-4444-000000000002"
          },
          "uuid":"11111111-2222-3333-4444-000000000002",
          "volume_change": -7.1
        }
      }
      """
      Then I should have a plate with uuid "11111111-2222-3333-4444-000000000003" with the following wells volumes:
       | well_location | current_volume  |
       | B1            | 37.2              |
       | B2            | 27.2              |
       | B3            | 37.2              |
       | B4            | 37.2              |
       | B5            | 37.2              |
       | B6            | 37.2              |


