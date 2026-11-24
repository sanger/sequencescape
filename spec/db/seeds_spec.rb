# frozen_string_literal: true

require 'rails_helper'

# Seeding must never run in the deployed environments. UAT runs with the
# Rails environment staging.
RSpec.describe 'db/seeds.rb' do # rubocop:disable RSpec/DescribeClass
  %w[staging training production].each do |environment|
    it "refuses to seed the #{environment} database" do
      allow(Rails).to receive(:env)
        .and_return(ActiveSupport::EnvironmentInquirer.new(environment))

      expect { load Rails.root.join('db/seeds.rb') }
        .to raise_error(StandardError, /SERIOUSLY, YOU DON'T WANT TO DO THIS/)
    end
  end
end
