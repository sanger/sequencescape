#
# THIS COMPLETE FEATURE IS DEPRECATED BY DPL-417 ACCEPTANCE CRITERIA
#
# @pipeline
# Feature: Sequencing pipelines should display submitted at date.

#   Background:
#     Given I am a "administrator" user logged in as "John Smith"
#     And all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

#   Scenario: Standard Sequencing page
#     Given Pipeline "HiSeq Cluster formation PE (spiked in controls)" and a setup for submitted at
#     Given I am on the show page for pipeline "HiSeq Cluster formation PE (spiked in controls)"
#     Then show me the page
#     And I should see "Submitted at"
#     And I should see "2010-10-23"
