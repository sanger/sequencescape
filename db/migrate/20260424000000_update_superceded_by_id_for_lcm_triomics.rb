# frozen_string_literal: true

# Updates the superceded_by_id of 'Limber-Htp - LCM Triomics' to the id of
# 'Limber-Htp - LCM Triomics EMSeq', marking it as superseded.
class UpdateSupercededByIdForLcmTriomics < ActiveRecord::Migration[8.0]
  def up
    emseq_template = SubmissionTemplate.find_by(name: 'Limber-Htp - LCM Triomics EMSeq')
    raise "Could not find submission template 'Limber-Htp - LCM Triomics EMSeq'" if emseq_template.nil?

    triomics_template = SubmissionTemplate.find_by(name: 'Limber-Htp - LCM Triomics')
    raise "Could not find submission template 'Limber-Htp - LCM Triomics'" if triomics_template.nil?

    current_time = Time.current
    triomics_template.update!(
      superceded_by_id: emseq_template.id,
      superceded_at: current_time,
      updated_at: current_time
    )
  end

  def down
    triomics_template = SubmissionTemplate.find_by(name: 'Limber-Htp - LCM Triomics')
    return if triomics_template.nil?

    current_time = Time.current
    triomics_template.update!(
      superceded_by_id: -1,
      superceded_at: nil,
      updated_at: current_time
    )
  end
end
