# frozen_string_literal: true

# Updates the superceded_by_id of 'Limber-Htp - LCM Triomics' to the id of
# 'Limber-Htp - LCM Triomics EMSeq', marking it as superseded.
class UpdateSupercededByIdForLcmTriomics < ActiveRecord::Migration[8.0]
  def up
    # find the new template
    emseq_template = SubmissionTemplate.find_by(name: 'Limber-Htp - LCM Triomics EMSeq')
    # find the old template
    triomics_template = SubmissionTemplate.find_by(name: 'Limber-Htp - LCM Triomics')

    # update the old template to be superseded by the new template
    current_time = Time.current
    triomics_template.update!(
      superceded_by_id: emseq_template.id,
      superceded_at: current_time
    )
  end

  def down
    triomics_template = SubmissionTemplate.find_by(name: 'Limber-Htp - LCM Triomics')
    return if triomics_template.nil?

    # reset the superceded_by_id and superceded_at fields to their original values
    # -1 indicates that the template is lastest version, in use
    triomics_template.update!(
      superceded_by_id: -1,
      superceded_at: nil
    )
  end
end
