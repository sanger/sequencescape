# Single use rake tasks

This folder contains one-off rake tasks that are not intended to be run on a regular basis. They are typically used for data migrations, cleanup, or other maintenance tasks that need to be performed only once.
These are separate from database migrations which are versioned changes to the database contents.
It is useful to keep these tasks so we can track what has been done and when.

### Usage

- File names should be descriptive of the task being performed.
- File names should contain the date the task was created in the format `YYYY_MM_<task_name>.rb` to help with organization and tracking.
- Tasks should be under the `single_use` namespace to avoid conflicts with other rake tasks.

To run a single use rake task, you can use the following command:

```
bundle exec rake single_use:<task_name>
``` 

### Testing
- Spec files for single use rake tasks should be placed in the same directory as the task file and should have the same name as the task file with `_spec.rb` appended to the end.
- These are useful to verify that the task is working as expected at the time of creation, but do not need to be maintained over time as the codebase changes.
- These will *not* be run as part of the normal test suite, but can be run manually using the following command:

```
bundle exec rspec lib/tasks/single_use/<task_name>_spec.rb
```