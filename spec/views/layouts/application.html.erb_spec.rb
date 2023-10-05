# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'layouts/application', type: :view do
  environments = {
    cucumber: "🥒",
    development: "🚧",
    # production is tested separately
    profile: "⏱️",
    staging: "🚀",
    staging_2: "🚀2️⃣",
    test: "🧪",
    training: "🎓",
  }

  environments.each do |env, emoji|
    it "displays the correct title with #{emoji} for #{env} environment" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(env.to_s))
      assign(:page_name, 'the homepage')
      render
      expect(rendered).to have_title("#{emoji}: Sequencescape : Test - the homepage")
    end
  end

  it 'displays the correct title without emoji in production environment' do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
    assign(:page_name, 'the homepage')
    render
    expect(rendered).to have_title("Sequencescape : Test - the homepage")
  end

  it 'displays the correct title with question mark emoji for undefined environment' do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('undefined_environment'))
    assign(:page_name, 'the homepage')
    render
    expect(rendered).to have_title("❓: Sequencescape : Test - the homepage")
  end
end
