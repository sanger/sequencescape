# frozen_string_literal: true

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
    class TransferTemplateLoader < ApplicationRecordLoader
        config_folder 'transfer_templates'
    end

    def create_or_update(name, options)
        TransferTemplate.create_with(options).find_or_create_by!(name: name)
    end
end