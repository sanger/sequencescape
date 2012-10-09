@api @json @<%= singular_name %> @single-sign-on @new-api
Feature: Access <%= plural_human_name %> through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual <%= plural_human_name %> through their UUID
  And I want to be able to perform other operations to individual <%= plural_human_name %>
  And I want to be able to do all of this only knowing the UUID of a <%= singular_human_name %>
  And I understand I will never be able to delete a <%= singular_human_name %> through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
<% if can_create? -%>

  @create
  Scenario: Creating a <%= singular_human_name %>
    Given the UUID of the next <%= singular_human_name %> created will be "00000000-1111-2222-3333-444444444444"

    When I POST the following JSON to the API path "/<%= plural_name %>":
      """
      {
        "<%= singular_name %>": {

        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "<%= singular_name %>": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """

  @create @error
  Scenario: Creating a <%= singular_human_name %> which results in an error
    When I POST the following JSON to the API path "/<%= plural_name %>":
      """
      {
        "<%= singular_name %>": {

        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
     And the JSON should be:
      """
      {
        "content": {
          "field_in_error": ["error message!"]
        }
      }
      """

<% end -%>
<% if can_update? -%>
  @update @error
  Scenario: Updating the <%= singular_human_name %> associated with the UUID which gives an error
    Given the <%= singular_human_name %> exists with ID 1
      And the UUID for the <%= singular_human_name %> with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "<%= singular_name %>": {

        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          "field_in_error": [ "error message!" ]
        }
      }
      """

  @update
  Scenario: Updating the <%= singular_human_name %> associated with the UUID
    Given the <%= singular_human_name %> exists with ID 1
      And the UUID for the <%= singular_human_name %> with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "<%= singular_name %>": {

        }
      }
      """
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "<%= singular_name %>": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """
<% end -%>

  @read
  Scenario: Reading the JSON for a <%= singular_human_name  %> UUID
    Given the <%= singular_human_name %> exists with ID 1
      And the UUID for the <%= singular_human_name %> with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "<%= singular_name %>": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """
