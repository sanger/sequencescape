@api @json @supplier @single-sign-on @new-api
Feature: Access suppliers through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual suppliers through their UUID
  And I want to be able to perform other operations to individual suppliers
  And I want to be able to do all of this only knowing the UUID of a supplier
  And I understand I will never be able to delete a supplier through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API


  @paging
  Scenario: Retrieving the first page of suppliers when none exist
    When I GET the API path "/suppliers"
    Then the HTTP response should be "200 OK"
    And the JSON should be:
      """
      {
        actions: {
          read: "http://www.example.com/api/1/suppliers/1",
          first: "http://www.example.com/api/1/suppliers/1",
          last: "http://www.example.com/api/1/suppliers/1"
        },
        suppliers: [ ],
        uuids_to_ids: { }
      }
      """

  # TODO: This should be an error but there is no way to support that at the moment
  @paging
  Scenario: Retrieving past the end of the pages
    When I GET the API path "/suppliers/2"
    Then the HTTP response should be "404 Not Found"
    And the JSON should be:
      """
      {
        general: [ 'past the end of the results' ]
      }
      """

  @paging
  Scenario: Retrieving the page of suppliers when only one page exists
    Given a supplier called "John's Genes" with ID 1
    And the UUID for the supplier "John's Genes" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/suppliers"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        actions: {
          read: "http://www.example.com/api/1/suppliers/1",
          first: "http://www.example.com/api/1/suppliers/1",
          last: "http://www.example.com/api/1/suppliers/1"
        },
        suppliers: [
          {
            actions: {
              read: "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
            },

            uuid: "00000000-1111-2222-3333-444444444444"
          }
        ],
        uuids_to_ids: {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """

  @paging
  Scenario Outline: Retrieving the pages of suppliers
    Given 3 suppliers exist with names based on "John's Genes" and IDs starting at 1
    And all suppliers have sequential UUIDs based on "11111111-2222-3333-4444"

    When I GET the API path "/suppliers/<page>"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        actions: {
          first: "http://www.example.com/api/1/suppliers/1",
          read: "http://www.example.com/api/1/suppliers/<page>",
          <extra paging>,
          last: "http://www.example.com/api/1/suppliers/3"
        },
        suppliers: [
          {
            actions: {
              read: "http://www.example.com/api/1/11111111-2222-3333-4444-<uuid>"
            },

            uuid: "11111111-2222-3333-4444-<uuid>"
          }
        ],
        uuids_to_ids: {
          "11111111-2222-3333-4444-<uuid>": <id>
        }
      }
      """

    Examples:
      | page | id | uuid         | extra paging                                                                                                           |
      | 1    | 1  | 000000000001 | next: "http://www.example.com/api/1/suppliers/2"                                                               |
      | 2    | 2  | 000000000002 | next: "http://www.example.com/api/1/suppliers/3", previous: "http://www.example.com/api/1/suppliers/1" |
      | 3    | 3  | 000000000003 | previous: "http://www.example.com/api/1/suppliers/2"                                                           |

  @read @error
  Scenario: Reading the JSON for a UUID that does not exist
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"
    And the JSON should be:
      """
      {
        general: [ "UUID does not exist" ]
      }
      """

  @read
  Scenario: Reading the JSON for a UUID
    Given a supplier called "John's Genes" with ID 1
    And the UUID for the supplier "John's Genes" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        supplier: {
          actions: {
            read: "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          sample_manifests: {
            actions: {
              read: "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_manifests"
            }
          },

          uuid: "00000000-1111-2222-3333-444444444444",
          name: "John's Genes",
          email: null,
          address: null,
          contact_name: null,
          phone_number: null,
          fax: null,
          url: null,
          abbreviation: null
        },
        uuids_to_ids: {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """
