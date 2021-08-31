# frozen_string_literal: true
module SharedBehaviour::Indestructable # rubocop:todo Style/Documentation
  def self.included(base)
    base.class_eval { before_destroy :prevent_destruction }
  end

  private

  def prevent_destruction
    errors.add(:base, 'can not be destroyed and should be deprecated instead!')
    throw(:abort)
  end
end
