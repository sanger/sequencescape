@accession_number @accession-service
Feature: object with an accession should be modifiable
  Background:
    Given I am an "administrator" user logged in as "me"
    And all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

  Scenario: A released sample with already an accession number should submit okay
    Given a sample named "sample" exists for accession
    And the sample name "sample" has previously been released
    And the sample "sample" has the accession number "E-ERA-16"
    Given an accessioning webservice exists which returns a sample accession number "E-ERA-16"
    When I update an accession number for sample "sample"

    When ignoring "CONTACTS" the XML submission for the sample "sample" should be:
        """
  <?xml version="1.0" encoding="UTF-8"?>
  <SUBMISSION center_name="SC" broker_name="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" alias="sample-sc-2010-10-23T23:00:00Z-200" submission_date="2010-10-23T23:00:00Z">
    <ACTIONS>
      <ACTION>
        <MODIFY source="sample-sc-2010-10-23T23:00:00Z-200.sample.xml" target="E-ERA-16" schema="sample"/>
      </ACTION>
    </ACTIONS>
  </SUBMISSION>
        """
       
  Scenario: A unreleased sample with already an accession number should behave as normal
    Given a sample named "sample" exists for accession
    And the sample "sample" has the accession number "E-ERA-16"
    Given an accessioning webservice exists which returns a sample accession number "E-ERA-16"
    When I update an accession number for sample "sample"

    When ignoring "CONTACTS" the XML submission for the sample "sample" should be:
        """
  <?xml version="1.0" encoding="UTF-8"?>
  <SUBMISSION center_name="SC" broker_name="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" alias="sample-sc-2010-10-23T23:00:00Z-200" submission_date="2010-10-23T23:00:00Z">
    <ACTIONS>
      <ACTION>
        <MODIFY source="sample-sc-2010-10-23T23:00:00Z-200.sample.xml" target="E-ERA-16" schema="sample"/>
      </ACTION>
      <ACTION><HOLD/></ACTION>
    </ACTIONS>
  </SUBMISSION>
        """