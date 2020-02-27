# Be sure to restart your server when you modify this file.
# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += [
  'disable_animations.css',
  'sessions.css',
  'print.css',
  'scanned_barcode.js',
  'pipeline.js',
  'assign-tubes-to-wells-task.js',
  'assigntags.js',
  'characterisation.js',
  'descriptors.js',
  'fail_batch.js',
  'labwhere_reception.js',
  'organism_validation.js',
  'pipeline.js',
  'pooling.js',
  'sample_move.js',
  'submissions.js',
  'bulk_submissions.js',
  'JsBarcode.all.min.js',
  'print_swipecard.js',
  'report_fails.js'
]