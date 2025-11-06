@qc  @roles
Feature: Set roles for SLF functionality
  As a lab manager in SLF I want to allow some of my staff access to certain functions
  and restrict the rest to myself only.

  @gel
  Scenario Outline: View Gel page with invalid role
    Given I am an "<role>" user logged in as "john"
    And I allow redirects and am on the gel QC page
    Then I should not see "Find gel plate"
    Examples:
    | role        |
    | follower    |
    | internal    |
    | lab         |
    | lab_manager |
    | manager     |
    | owner       |

  @gel
  Scenario Outline: View Gel page with valid role
    Given I am an "<role>" user logged in as "john"
    And I am on the gel QC page
    Then I should see "Find gel plate"
    Examples:
    | role          |
    | slf_gel       |
    | slf_manager   |
    | administrator |

  @plate_template
  Scenario Outline: View Plate template page with invalid role
    Given I am an "<role>" user logged in as "john"
    And I am on the plate template homepage
    Then I should not see "New 96 Template"
    Examples:
    | role        |
    | follower    |
    | internal    |
    | lab         |
    | lab_manager |
    | manager     |
    | owner       |
    | slf_gel     |

  @plate_template
  Scenario Outline: View Plate template page with valid role
    Given I am an "<role>" user logged in as "john"
    And I am on the plate template homepage
    Then I should see "New 96 Template"
    Examples:
    | role          |
    | slf_manager   |
    | administrator |

  @slf
  Scenario Outline: View SLF homepage with invalid role
    Given I am an "<role>" user logged in as "john"
    And I allow redirects and am on the sample logistics homepage
    Then I should not see "Sample Management"
    Examples:
    | role        |
    | follower    |
    | internal    |
    | lab         |
    | lab_manager |
    | manager     |
    | owner       |

  @slf
  Scenario Outline: View SLF homepage with valid role
    Given I am an "<role>" user logged in as "john"
    And I am on the sample logistics homepage
    Then I should see "Sample Management"
    When I follow "Sample Management Lab View"
    Then I should see "Print plate barcodes"
    Examples:
    | role          |
    | slf_manager   |
    | administrator |
    | slf_gel       |

  @slf @gel
  Scenario: View SLF homepage as slf gel user
    Given I am an "slf_gel" user logged in as "john"
    And I am on the sample logistics homepage
    Then I should see "Sample Management"
    And I should see "Gel"
    And I should not see "Suppliers"
    When I follow "Cherrypicking plate templates"
    Then I should not see "New 96 Template"
