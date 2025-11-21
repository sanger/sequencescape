# Accession Status Tracking

## Preamble

Prior to this piece of work, there were two ways to validate and accession samples (but only one for studies and other datatypes that can be accessioned) which caused headaches for developers and users alike. The initial way was to perform a synchronous request to EBI to submit the samples, but this proved too slow for the large batches of samples. There is also a known bug in the (now deprecated, but still in use) API that caused connection timeouts.
To address this, some early work was done to submit samples (only) via a delayed-jobs queue. While efficient, and more reliable, this asynchronous method broke the feedback loop to users when the submission failed. Developers were none the wiser due to the lack of error handling at the time, but now that (many) validation errors are being reported, it has become more obvious that the duplicate validation paths are proving troublesome. This piece of work (Y25-286) looks to address this by reducing the execution paths and duplicate code for sample accessioning, and restoring the feedback loop to users.

In an attempt to reduce the number of execution paths for the accessioning of samples specifically we are going to accession both individual samples and all groups of samples (manifests and studies) using the delayed jobs workers. While this has a number of advantages (explained below), there is currently no method to return feedback to the submitting user. To address this, we are going add database-backed records of the state of each item that is being accessioned.

## Accessioning demand

Looking at accessioning logs for the delayed jobs path over the last month shows that 4 workers process sample accessions in parallel at a combined rate of ~1000 samples/second. While the number of accessions submitted at a time can vary, it is not uncommon to receive requests to process ~5000 samples at a time.

## Multiple APIs

Sequencescape currently uses the original v1 accessioning API provided by EBI (https://ena-docs.readthedocs.io/en/latest/submit/general-guide/webin-v1.html). This has been replaced with a v2 API (https://ena-docs.readthedocs.io/en/latest/submit/general-guide/programmatic.html) which has better support for large submissions.

## Robustness

The delayed job queue allows many accessions to be submitted, but will also retry them should the submission fail. This is particularly helpful if there is an outage on the EBI side.

## Model design

To address the lack of feedback outlined above, a new models and database table are to be created:

- `Accession:Status` tracks the status and feedback from individual sample accessions

While this is currently intended to be used only with sample accessions, there is no reason why it could not be used for other accession types in the future.

This is intended to work as follows:

1. A user would submit a sample manifest, accession all samples within a study, or accession individual samples.
2. Each of these actions would create a individual Accession::Status record for each item to be accessioned.
3. If the accessioning process succeeds, the accession number would be updated on the object itself.
4. If the accessioning process fails, the status record would be updated to 'failed' with the given error message.
5. All successful statuses would be removed after notification, while failed statuses would be retained for user reference.
6. Statuses can be deleted after a rolling period of time, say 30 days.
