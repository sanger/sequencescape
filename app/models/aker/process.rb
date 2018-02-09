module Aker
  class Process < ApplicationRecord
    validates :name, :tat, presence: true
    validates :name, uniqueness: true

    has_many :product_processes, foreign_key: :aker_process_id, dependent: :destroy
    has_many :products, through: :product_processes
    has_many :process_module_pairings, class_name: 'ProcessModulePairing', foreign_key: :aker_process_id, dependent: :destroy

    def as_json(_options = {})
      {
        id: id,
        name: name,
        tat: tat,
        process_module_pairings: process_module_pairings
      }
    end
  end
end
