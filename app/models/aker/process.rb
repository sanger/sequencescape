module Aker
  class Process < ApplicationRecord
    validates :name, :tat, presence: true
    validates :name, uniqueness: true

    has_many :product_processes, foreign_key: :aker_process_id, dependent: :destroy
    has_many :products, through: :product_processes
    has_many :process_module_pairings, class_name: 'ProcessModulePairing', foreign_key: :aker_process_id, dependent: :destroy

    def as_json(options = {})
      {
        id: id,
        name: name,
        TAT: tat,
        process_module_pairings: process_module_pairings,
        stage: stage(options[:product_id])
      }
    end

    private

    def stage(product_id)
      product_process = product_processes.find_by(aker_product_id: product_id, aker_process_id: id)
      product_process.stage if product_process.present?
    end
  end
end
