Feature: You should be able to create a study if a study owner has a blank last name

  Scenario: create study where owner has blank last name
    Given I am an "administrator" user logged in as "John Smith"
    And I have an "active" study called "Test study"
    Given the following user records
      | login  | first_name    | last_name |
      | xyz1   | John          | Smith     |
      | xyz2   |               |           |
    And the study "Test study" has the following contacts
      | login | role     |
      | xyz1  | owner    |
      | xyz2  | owner    |
    Given user "xyz2" has nil first and last names

    Given I am on the homepage
    When I follow "Create study"
    Then I should see "To register a new study"
