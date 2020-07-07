---
name: New Library Type
about: Template for describing new library types.
title: "[Library Type]"
labels: enhancement
assignees: ''

---

**User story**
The clear and concise user story describing what is required. e.g. As an SSR user I would like the library type 'PCR amplicon ligated adapters' in order to process...

**Who are the primary contacts for this story**
For new library types it is helpful if we have an SSR, and a member of operations and R&D
e.g. John S (don't include surnames in public repos)

*** Library type name ***
What name should be used for the library type? This name will be the option picked from the library type drop down in the library manifest and submission. It will also be presented in the ML warehouse in the id_pipeline_lims field.

*** Go live date ***
When is the library type expected to go live.

*** Request Types ***
If known, please supply a list of request_types on which this library type will be available.

** Submission Template ***
If unsure above, which submission templates should the library type be available for?
A list of submission templates is available from:
http://sequencescape.psd.sanger.ac.uk/bulk_submissions/new

*** Limber ***
Will the library type be associated with an existing Limber pipeline? If a new pipeline is required, please link the corresponding limber issue here.

*** Checklist ***
[ ] NPG consulted
[ ] Faculty affected

**Dependencies**
This story is blocked by the following dependencies:
- #<issue_no.>
- sanger/<repo>#<issue_no.>

**Additional context**
Add any other context or screenshots about the feature request here.

*** Developer Checklist ***
[ ] Library type associated with correct request types
[ ] Library Type associated with limber pipelines
