# frozen_string_literal: true

class DefaultValidator < ActiveModel::Validator

  def validate(_)
    true
  end

end
