require File.dirname(__FILE__) + '/globals'
require File.dirname(__FILE__) + '/support/options'

module Informatics
  class Application
    include Informatics::Globals

    attr_accessor :name, :description, :home_page, :title, :authentication

    def self.configure
      a = new
      yield a
      @@application = a
    end

    def named(name)
      @name = name
    end

    def authenticate_via(type)
      @authentication = type
    end

    def subtitle(t)
      @title = t
    end

    def described_as(desc)
      @description = desc
    end

    def home_page_link(link)
      @home_page = link
    end
  end
end
