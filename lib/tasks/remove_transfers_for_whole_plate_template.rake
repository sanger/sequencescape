# frozen_string_literal: true

namespace :transfers do
  desc "Removing transfers from transfer template 'Whole plate to tube'"
  task remove: :environment do
    ActiveRecord::Base.transaction do
      template = TransferTemplate.find_by(name: 'Whole plate to tube')
      unless template.nil?
        template.transfers = nil
        template.save
      end
    end
  end
end
