# frozen_string_literal: true

FactoryBot.define do
  factory(:pooled_plate_creation) do
    child_purpose { |target| target.association(:plate_purpose) }
    user { |target| target.association(:user) }

    # When giving a tube as a parent, we change the prefix away from NT to avoid clashes with tubes created as children
    # by other instances of this model.
    parents { |target| [target.association(:plate), target.association(:tube, prefix: 'PT')] }
  end
end
