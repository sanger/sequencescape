# frozen_string_literal: true

# Update the flexible cherrypick pipeline to prepare for removal
class RemoveFlexibleCherrypickPipeline < ActiveRecord::Migration[6.0]
  def up
    Pipeline.where(sti_type: %w[FlexibleCherrypickPipeline]).update_all(sti_type: 'LegacyPipeline', active: false)
  end

  def down
    raise ActiveRecord::IrreversibleMigration unless ENV['NO_REALLY'] == 'true'

    # The following code makes assumptions about names, and mimic the production
    # state when the migration was written.
    [['Flexible Cherrypick', 'FlexibleCherrypickPipeline']].each do |name, sti_type|
      pipeline = Pipeline.find_by(name:)
      next if pipeline.nil?

      pipeline.update!(sti_type:, active: true)
    end
  end
end
