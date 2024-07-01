# frozen_string_literal: true

class NovaSeq6000Validator < ActiveModel::Validator

  def validate(record)
    record.errors.add :base, 'NovaSeq6000Validator failed'
  end

end
