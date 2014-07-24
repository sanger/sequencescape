@lane @data_release @external_release @11233725
Feature: Externally releasing a passed or failed lane should display the correct options in the dropdown

  Background:
    Given I am an "administrator" user logged in as "John Doe"

    Scenario Outline:
      Given a lane named "<name_lane>" exists
      Given an <external_release> lane named "<name_lane>"
      Given a state "<status>" to lane named "<name_lane>"
      And I am on the show page for asset "<name_lane>"
      When I follow "Edit"
      When I select "<option>" from "Reason for releasing data"
      Examples:
        | name_lane    | status | external_release | option                                                             |
        | first_asset  | passed | releasable       | Unsure data source                                                 |
        | first_asset  | passed | releasable       | GC bias in data set                                                |
        | first_asset  | passed | releasable       | Multiplex tag problems in data set                                 |
        | first_asset  | passed | releasable       | Data doesn't reflect the experiment                                |
        | first_asset  | passed | releasable       | Data doesn't contain any of the expected organism                  |
        | second_asset | failed | unreleasable     | Failed on yield but sufficient data for experiment                 |
        | second_asset | failed | unreleasable     | Failed on quality but sufficient data for experiment               |
        | second_asset | failed | unreleasable     | Failed on adapter contamination but data sufficient for experiment |


