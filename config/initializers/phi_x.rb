# frozen_string_literal: true

phi_x_config = YAML.load_file('config/phi_x.yml')
Rails.application.config.phi_x = phi_x_config.with_indifferent_access
