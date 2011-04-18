# Causes the locale files to be pre-processed with ERB as we need to perform some substitutions
module I18n
  module Backend
    module Base
      def load_yml(filename)
        YAML::load(ERB.new(IO.read(filename)).result)
      end
    end
  end
end
