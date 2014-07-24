@sample @manifest @supplier
Feature: Manage sample suppliers
  Manage sample suppliers

  Background:
    Given I am an "External" user logged in as "abc123"

  Scenario: Create a supplier
    Given I am on the sample db homepage
    When I follow "Create supplier"
    Then I should see "New Supplier"
    When I fill in "Name" with "Test supplier name"
     And I fill in "Address" with "WTSI, Cambridge, UK"
     And I fill in "Contact name" with "John Doe"
     And I fill in "Email" with "test@example.com"
     And I fill in "Phone number" with "1234567"
     And I press "Create Supplier"
    Then I should see "Supplier was successfully created"
    And I should be on the sample db homepage
    When I follow "View all suppliers"
    Then I should see "Test supplier name"
     And I should see "John Doe"

  Scenario: Edit an existing supplier
    Given a supplier called "Test supplier name" exists
    Given I am on the sample db homepage
    When I follow "View all suppliers"
     And I follow "Test supplier name"
     And I follow "Edit"
    When I fill in "Name" with "New supplier name"
     And I press "Update Supplier"
    Then I should see "Supplier was successfully updated"
     And I should see "New supplier name"

