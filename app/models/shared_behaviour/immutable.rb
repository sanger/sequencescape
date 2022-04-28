# frozen_string_literal: true
module SharedBehaviour::Immutable # rubocop:todo Style/Documentation
  MUTABLE = %w[deprecated_at updated_at].freeze

  def self.included(base)
    base.class_eval { before_update :save_allowed? }
  end

  private

  def save_allowed?
    return true if (changed - MUTABLE).empty?

    raise ActiveRecord::RecordNotSaved, 'This record is immutable. Deprecate it and create a replacement instead.'
  end
end
