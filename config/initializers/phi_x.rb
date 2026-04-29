# frozen_string_literal: true

phi_x_config = YAML.safe_load_file('config/phi_x.yml')
Rails.application.config.phi_x = phi_x_config.with_indifferent_access
