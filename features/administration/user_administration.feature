@javascript @admin @user @role
Feature: Manage users
  As an administrator I would like to manage my users accounts details.
  I would also like to add and remove roles, both universally and on a project/study basis

  Background:
    Given I am a "administrator" user logged in as "user"
    And I am on the homepage
    Given I have an active study called "Test study"
    Given I have an active project called "Test project"
    When I follow "Admin"
    Then I should see "Administration"
    Given user "john" exists
    When I follow "User management"
    Then I should see "Registered users"
    And I should see "john"
    When I follow "Edit user john"
    Then I should see "Edit profile: John Smith"

  Scenario Outline: Edit a user and give them universal roles
    Given the role "<role_name>" exists
    When I fill in the following:
     | First name | Jack              |
     | Last name  | Doe               |
     | Email      | jack@example.com |
    And I check "<role>"
    And I press "Update"
    Then I should see "Profile updated"
    And I should see "Jack"
    And I should see "Doe"
    And the user "jack@example.com" roles should look like:
      | role    |
      | <role_name> |

    Examples:
      | role            | role_name |
      | Administrator   | administrator |
      | Manager         | manager       |
      | Internal        | internal |
      | Lab             | lab |
      | Lab manager     | lab_manager |
      | Owner           | owner |
      | SLF lab manager | slf_manager |
      | SLF Gels        | slf_gel |

  # not anymore. so tell me (xxx) if the fix doesn't work
  @known_to_fail_randomly
  Scenario Outline: Give a user a role specific
    When I select "administrator" from "<up_case_class> role" within "div#<downcase_class>_role"
    And I select "Test <downcase_class>" from "for <up_case_class>" within "div#<downcase_class>_role"
    And I press "Add <up_case_class> role" within "div#<downcase_class>_role"
    Then I should see "Administrator"
    Then the role list table should look like:
      | Role          | Type    | Name         |
      | Administrator | <up_case_class> | Test <downcase_class> |
    Examples:
      | up_case_class | downcase_class |
      | Project       | project        |
      | Study         | study          |


