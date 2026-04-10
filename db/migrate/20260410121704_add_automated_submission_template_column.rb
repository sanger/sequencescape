class AddAutomatedSubmissionTemplateColumn < ActiveRecord::Migration[8.0]
  def change
    add_column :submission_templates, :automated, :boolean, default: false, null: false

    # Automated submission templates at the time of this migration
    existing_automated_template_names = [
      'Limber-Htp - Bioscan Library Prep - Automated',
      'Limber-Htp - BGE Transition - Automated',
      'Limber-Htp - Ultima PCR Free - Ultima sequencing Automated',
      'Limber - Heron LTHR - Automated',
      'Limber - Heron LTHR V2 - Automated'
    ]

    SubmissionTemplate.where(name: existing_automated_template_names).each do |template|
      template.update!(automated: true)
    end
  end
end
