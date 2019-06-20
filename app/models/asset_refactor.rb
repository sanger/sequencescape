# frozen_string_literal: true

require 'rainbow'

# # Asset Refactor
# AssetRefactor provides a namespace for the refactor of {Asset} into Labware
# and Receptacle. It is intended to provide a route to help ease the transition
#
# This module contains tools to automatically detect when the new schema is loaded
# and enable the corresponding feature flags.
#
# You will not be able to dump the schema while these changes are in place, this is
# to prevent the new tables from becoming the default until the work to switch the
# schema over is complete.
#
# ## Help! I have some migrations I need to run
# If other migrations have been added and you want to run them then you'll need
# to run `rake db:reset` before re-running the asset re-factor migrations with
# `rake asset_refactor:migrate`
# This ensures that we know we can run the migrations against whatever schema changes
# we may see in future.
#
# ## Okay, I think we're ready, now what?
# Run `rake asset_refactor:finalize` and migrations in db/migrate_asset_refactor
# will be copied into db/migrate. New timestamps will be generated to ensure migrations
# run after any which already exist.
#
# @see AssetRefactor::Labware
#
# @author [jg16]
#
module AssetRefactor
  # Call in the initializer to detect if we're currently dealing with the re-factored
  # assets schema. Will be used to:
  # - Switch feature flags
  # - Prevent schema dumping
  def self.setup
    @refactor_env = ActiveRecord::Base.connection.tables.include?('labware')
    warning if @refactor_env
  rescue ActiveRecord::NoDatabaseError => _e
    warn 'No database detected'
    @refactor_env = false
  end

  def self.warning
    Rails.logger.warn Rainbow(<<~HEREDOC
      ⚠️ ⚠️ ⚠️
      ⚠️ ⚠️ ⚠️ Labware table detected. AssetRefactor mode enabled.
      ⚠️ ⚠️ ⚠️ See app/models/asset_refactor.rb for more information
      ⚠️ ⚠️ ⚠️
    HEREDOC
                             ).bg(:yellow).fg(:black)
  end

  #
  # Detects that the new asset tables are in place, and executes the enclosed block.
  #
  # @return [type] [description]
  def self.when_refactored
    setup unless defined?(@refactor_env)
    yield if @refactor_env
  end

  #
  # Detects that the new asset tables are NOT in place, and executes the enclosed block.
  #
  # @return [type] [description]
  def self.when_not_refactored
    setup unless defined?(@refactor_env)
    yield unless @refactor_env
  end
end
