# frozen_string_literal: true

FactoryBot.define do
  factory(:specific_tube_creation) do
    child_purposes { |target| [target.association(:tube_purpose), target.association(:tube_purpose)] }
    tube_attributes { [{ name: 'Tube one' }, { name: 'Tube two' }] }
    user { |target| target.association(:user) }

    # When giving a tube as a parent, we change the prefix away from NT to avoid clashes with tubes created as children
    # by other instances of this model.
    parents { |target| [target.association(:plate), target.association(:tube, prefix: 'PT')] }
  end
end
