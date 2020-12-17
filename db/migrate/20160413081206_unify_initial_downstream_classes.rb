# Multiple request classes have been combined into a single request, eliminating complexity
class UnifyInitialDownstreamClasses < ActiveRecord::Migration
  class Request < ApplicationRecord
    self.table_name = 'requests'
  end

  NEW_CLASS = 'TransferRequest::InitialDownstream'.freeze
  OLD_CLASSES = ['IlluminaHtp::Requests::PcrXpToPoolPippin', 'IlluminaHtp::Requests::PcrXpToPool',
                 'Pulldown::Requests::PcrXpToIscLibPool'].freeze

  STATE_MIGRATIONS = { 'Pulldown::Requests::PcrXpToIscLibPool' => {
    'nx_in_progress' => 'passed'
  } }.freeze

  def up
    ActiveRecord::Base.transaction do
      OLD_CLASSES.each do |old|
        RequestType.where(request_class_name: old).find_each do |rt|
          say "Updating: #{rt.name}"
          rt.update!(request_class_name: NEW_CLASS)
          upd = Request.where(request_type_id: rt.id, sti_type: old).update_all(sti_type: NEW_CLASS)
          say "Updated #{upd} requests", true
          STATE_MIGRATIONS.fetch(old, []).each do |old_state, new_state|
            say "Migrating from #{old_state} to #{new_state}", true
            upd = Request.where(request_type_id: rt.id, state: old_state).update_all(state: new_state)
            say "#{upd} migrated", true
          end
        end
      end
    end
  end

  def down
  end
end
