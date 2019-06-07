# frozen_string_literal: true

# Setup the asset refactor flags. Can be removed once the asset changes have gone live.
begin
  AssetRefactor.setup
rescue ActiveRecord::NoDatabaseError => _e
  warn 'No Database detected'
end
