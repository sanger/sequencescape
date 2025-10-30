# Accession Status Tracking

Designed to track the status of Sample accessioning requests in order to provide feedback to users.
Feedback is provided once all items within a given status group have been processed.
It could be expanded to track other accessionable types in the future.

A user would submit a sample manifest, accession all samples within a study, or accession individual samples.
Each of these actions would create a single Accession:StatusGroup record and an individual Accession::Status record for each item to be accessioned.
If the accessioning process succeeds, the accession number would be updated on the object itself.
If the accessioning process fails, the status record would be updated to 'failed' with the given error message.
Once all items within a group (e.g., all samples in a manifest) have either succeeded or failed, the user would be notified of the overall result.
All successful statuses would be removed after notification, while failed statuses would be retained for user reference.
