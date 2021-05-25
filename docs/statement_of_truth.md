# @title Statement of Truth

# Statement of Truth

Also see: https://ssg-confluence.internal.sanger.ac.uk/display/PSD/Statement+of+Truth

- Be pragmatic not dogmatic (use common sense).
- Follow the Style guide.
- Adhere to Rubocop (level to be determined).
- Test coverage should not drop.
- Tests to be written in RSpec for new stories. If the cost of moving existing tests to RSpec is minimal it should be encouraged.
- No more new cucumber features. If an existing feature is covered by the story it needs to be moved to RSpec integration test.
- Methods should be declared as private in a block rather than individually.
- Do not reinvent the wheel. Use Rails features and conventions wherever possible e.g ActiveModel::Model. Only use dynamic programming when absolutely necessary.
- Use Factories for ActiveRecord objects and plain ruby objects wherever possible.
- All Factories should be valid (i.e. Linted) and grouped sensibly.
- Controllers should follow the standard Rails conventions. No business logic.
- Add peformance tests.
- Use performance enhancements wherever possible e.g. Pluck, eager loading.
- Encourage reuse. Separation of concerns.
- Remove Dangerous Artifacts.
- Travis must pass before a branch is merged except for critical bug fixes.
- Any gems added to the Gemfile should be annotated with a comment as to what they do and how they are being used.
