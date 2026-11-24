# frozen_string_literal: true

# This is a holdover from when pipelines were primarily generated via seeds and migrations

DEV_ONLY = [
  {
    name: 'Illumina-C - Cherrypick Internally',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      asset_input_methods: ['select an asset group', 'enter a list of sample names found on plates'],
      request_types: ['illumina_c_cherrypick']
    }
  }
].freeze

DEV_ONLY.each { |params| SubmissionSerializer.construct!(params) }
