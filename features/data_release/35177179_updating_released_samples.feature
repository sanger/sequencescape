@accession_number @accession-service
Feature: object with an accession should be modifiable
  Background:
    Given I am an "administrator" user logged in as "me"
    And all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"
    Given a sample named "sample" exists for accession
    And the UUID for the last sample is "example-uuid"
    And the sample "sample" has the accession number "E-ERA-16"

  Scenario: A released sample with an accession number should submit okay
    Given the sample name "sample" has previously been released
    And an accessioning webservice exists which returns a sample accession number "E-ERA-16"
    When I update an accession number for sample "sample"

    When ignoring "CONTACTS" the XML submission for the sample "sample" should be:
        """
  <?xml version="1.0" encoding="UTF-8"?>
  <SUBMISSION center_name="SC" broker_name="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" alias="example-uuid20101023T2300" submission_date="2010-10-23T23:00:00Z">
    <ACTIONS>
      <ACTION>
        <MODIFY source="example-uuid-2010-10-23T23:00:00Z.sample.xml" schema="sample"/>
      </ACTION>
    </ACTIONS>
  </SUBMISSION>
        """

  Scenario: A unreleased sample with an accession number should behave as normal
    Given an accessioning webservice exists which returns a sample accession number "E-ERA-16"
    When I update an accession number for sample "sample"

    When ignoring "CONTACTS" the XML submission for the sample "sample" should be:
        """
  <?xml version="1.0" encoding="UTF-8"?>
  <SUBMISSION center_name="SC" broker_name="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" alias="example-uuid20101023T2300" submission_date="2010-10-23T23:00:00Z">
    <ACTIONS>
      <ACTION>
        <MODIFY source="example-uuid-2010-10-23T23:00:00Z.sample.xml" schema="sample"/>
      </ACTION>
      <ACTION><HOLD/></ACTION>
    </ACTIONS>
  </SUBMISSION>
        """
