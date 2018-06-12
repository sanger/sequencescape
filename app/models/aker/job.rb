# frozen_string_literal: true

module Aker
  # Individual element of work from a work order.
  class Job < ApplicationRecord
    has_many :sample_jobs, dependent: :destroy
    has_many :samples, through: :sample_jobs

    has_many :containers, through: :samples

    has_many :assets, through: :containers

    validates :aker_job_id, presence: true
    validates :aker_job_url, presence: true

    def as_json(_options = {})
      {
        job: {
          id: id,
          aker_job_id: aker_job_id
        }
      }
    end

    def updated_materials
      samples
    end

    def new_materials
      []
    end

    def changed_containers
      []
    end

    def material_message(sample)
      Aker::Material.new(sample).attributes
    end

    def container_message(_container)
      {}
    end

    def containers_message
      changed_containers.map { |c| container_message(c) }
    end

    def updated_materials_message
      updated_materials.map { |m| material_message(m) }
    end

    def new_materials_message
      new_materials.map { |m| material_message(m) }
    end

    def finish_message
      {
        job: {
          job_id: aker_job_id,
          updated_materials: updated_materials_message,
          new_materials: new_materials_message,
          containers: containers_message
        }
      }
    end
  end
end
