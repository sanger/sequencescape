# frozen_string_literal: true
# These settings were added to ease the migration from Rails 2 to Rails 3.
# An earlier comment implied they should be the rails 3 defaults, however
# as of Rails 5 the remaining settings don't seem to match defaults so have
# been left.

# Include Active Record class name as root for JSON serialized output.
ActiveRecord::Base.include_root_in_json = true

# Don't escape HTML entities in JSON, leave that for the #json_escape helper.
# if you're including raw json in an HTML page.
ActiveSupport.escape_html_entities_in_json = false
