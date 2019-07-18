# frozen_string_literal: true

# There are some samples that should always exist
Sample.create!(name: 'phiX_for_spiked_buffers') unless Rails.env.test?
