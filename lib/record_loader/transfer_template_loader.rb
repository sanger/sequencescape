# frozen_string_literal: true

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates transfer templates if they are not present
  class TransferTemplateLoader < ApplicationRecordLoader
    config_folder 'transfer_templates'

    def create_or_update!(name, options)
      TransferTemplate.create_with(options).find_or_create_by!(name: name)
    end
  end
end
