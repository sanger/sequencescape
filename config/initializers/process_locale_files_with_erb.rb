# frozen_string_literal: true
# Causes the locale files to be pre-processed with ERB as we need to perform some substitutions
module I18n
  module Backend
    module Base # rubocop:todo Style/Documentation
      def load_yml(filename)
        YAML.load(ERB.new(File.read(filename)).result)
      end
    end
  end
end
