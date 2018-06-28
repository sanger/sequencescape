# frozen_string_literal: true

# Pipelines should inherit from this class when they are no longer active
# When marking a pipeline as Legacy, include the date. This will allow
# for later migration and elimination of the pipeline
class LegacyPipeline < Pipeline
  self.inbox_partial = 'deprecated_inbox'
end
