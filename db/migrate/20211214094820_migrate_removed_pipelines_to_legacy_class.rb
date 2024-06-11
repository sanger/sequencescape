# frozen_string_literal: true

# These pipelines have been deprecated
# The code has been updated to ensure these classes inherit from LegacyPipeline
# but this migration will allow the removal of the classes themselves in the next
# release. Failure to run this migration before removing the classes will cause
# exceptions on loading the classes.
class MigrateRemovedPipelinesToLegacyClass < ActiveRecord::Migration[6.0]
  def up
    Pipeline
      .where(
        sti_type: %w[
          PacBioSequencingPipeline
          PacBioSamplePrepPipeline
          Pipeline
          GenotypingPipeline
          CherrypickForPulldownPipeline
        ]
      )
      .update_all(sti_type: 'LegacyPipeline')
  end

  def down
    raise ActiveRecord::IrreversibleMigration unless ENV['NO_REALLY'] == 'true'

    # The following code makes assumptions about names, and mimic the production
    # state when the migration was written.
    [
      ['PacBio Sequencing', 'PacBioSequencingPipeline'],
      ['PacBio Library Prep', 'PacBioSamplePrepPipeline'],
      ['PacBio Tagged Library Prep', 'PacBioSamplePrepPipeline'],
      ['Cluster formation (old)', 'Pipeline'],
      ['MX Library creation', 'Pipeline'],
      %w[Genotyping GenotypingPipeline],
      ['Cherrypicking for Pulldown', 'CherrypickForPulldownPipeline']
    ].each do |name, sti_type|
      pipeline = Pipeline.find_by(name:)
      next if pipeline.nil?

      pipeline.update!(sti_type:)
    end
  end
end
