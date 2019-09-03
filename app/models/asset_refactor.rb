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
end
