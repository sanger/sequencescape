# frozen_string_literal: true

# This module is used to create a substitution hash to be used in TagSubstitution library
# after an aliquot is updated (saved), it uses aliquot.saved_changes to create substitution hash
# substitution hash is then used by TagSubstitution to find similar aliquots and update them
module Aliquot::DataForSubstitution
  def substitution_hash
    return if id_previously_changed?

    generate_substitution_hash if saved_changes?
  end

  def generate_substitution_hash
    aliquot_identifiers.merge(tag_id_substitution).merge(tag2_id_substitution).merge(other_attributes_for_substitution)
  end

  def tag_id_substitution
    return {} if changes[:tag_id].blank?

    { original_tag_id:, substitute_tag_id: }
  end

  def tag2_id_substitution
    return {} if changes[:tag2_id].blank?

    { original_tag2_id:, substitute_tag2_id: }
  end

  def original_tag_id
    changes[:tag_id].first
  end

  def substitute_tag_id
    changes[:tag_id].last
  end

  def original_tag2_id
    changes[:tag2_id].first
  end

  def substitute_tag2_id
    changes[:tag2_id].last
  end

  def other_attributes_for_substitution
    changes.transform_values(&:last).except(:updated_at, :tag_id, :tag2_id)
  end

  def changes
    @changes ||= saved_changes
  end

  private

  def aliquot_identifiers
    { sample_id:, library_id: }
  end
end
