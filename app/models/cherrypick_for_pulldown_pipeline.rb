# frozen_string_literal: true

# This class used to handle a semi-automated cherrypicking pipeline
# This class can be removed completely once migration:
# db/migrate/20211214094820_migrate_removed_pipelines_to_legacy_class.rb
# has been run.
class CherrypickForPulldownPipeline < LegacyPipeline
end
