# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2013,2014,2015 Genome Research Ltd.

# The classes within this namespace are responsible for defining the abilities of the user and the application
# that are accessing the API.
#
#--
# To maintain the behaviour of the API before this was introduced the logic is very straight-forward:
#
# 1. If the application is authorised then everything is possible.
# 2. If the application is unauthorised then the user capabilities take priority.
#
# There are several pieces of functionality that are always accessible:
#
# - UUID lookups are always available
# - Searches are always available
# - Submissions can be created and updated
# - Sample manifests can be created through studies and updated individually
#
# In the future we'll be able to adjust this and get the right behaviour based on the combination of the
# application and the user.  We'll also be able to extend the application abilities so that they are refined
# for certain applications.
#++
module Core::Abilities
  def self.create(request)
    CompositeAbility.new(request)
  end

  module ActionBehaviour
    # Modify the behaviour so that we can only access the action if the ability permits and the super
    # implementation permits it too.
    def accessible_action?(handler, action, request, object)
      request.ability.can?(action, handler, object) and super
    end
    private :accessible_action?
  end

  class CompositeAbility #:nodoc:
    attr_reader :user, :application
    private     :user, :application

    def initialize(request)
      @user, @application = User.new(request), Application.new(request)
      @application.authenticate!(@user)
    end

    def can?(*args, &block)
      application.can?(*args, &block) or user.can?(*args, &block)
    end
  end

  class Base
    class Recorder #:nodoc:
      def initialize
        @recorded = []
      end

      def play_back(target)
        @recorded.each { |block| target.instance_eval(&block) }
      end

      def record(&block)
        @recorded << block
      end
    end

    module ClassMethods
      def recorder_helper(name)
        line = __LINE__ + 1
        singleton_class.class_eval("
          def #{name}(&block)
            record(@#{name} ||= Recorder.new, &block)
          end
        ", __FILE__, line)
      end

      def record(recorder, &block)
        recorder.tap { |recorder| recorder.record(&block) if block_given? }
      end
      private :record
    end

    require 'cancan'
    include ::CanCan::Ability
    extend ClassMethods

    recorder_helper(:full)
    recorder_helper(:unregistered)

    def initialize(request)
      @request = request
      abilitise(:unregistered)
      abilitise(privilege) if registered?
    end

    def abilitise(name)
      self.class.send(name).play_back(self)
    end
    private :abilitise
  end

  class User < Base
    unregistered do
      # The API is designed to be read-only, at least.
      can(:read, :all)
    end

    recorder_helper(:authenticated)

    authenticated do
      # Submissions should be createable & updateable by anyone
      can(:create, Endpoints::Submissions::Model)
      can(:create, Endpoints::OrderTemplates::Instance::Orders)
      can(:update, Endpoints::Orders::Instance)
      can(:create, Endpoints::Submissions::Instance::Submit)
      can(:update, Endpoints::Submissions::Instance)

      # Sample manifests should also be createable & updateable by anyone
      can(:update, Endpoints::SampleManifests::Instance)
      can(:create, Endpoints::Studies::Instance::SampleManifests::CreateForPlates)
      can(:create, Endpoints::Studies::Instance::SampleManifests::CreateForTubes)
      can(:create, Endpoints::Studies::Instance::SampleManifests::CreateForMultiplexedLibraries)
    end

    def registered?
      false
    end
    private :registered?

    # Updates the abilities of the user based on the currently authenticated user instance.  If the user
    # unauthenticated then the API remains read-only.
    def authenticated!
      abilitise(:authenticated) if @request.user.present?
    end
  end

  class Application < Base
    recorder_helper(:tag_plates)

    def initialize(request)
      @api_application = ApiApplication.find_by(key: request.authorisation_code)
      super
    end

    def privilege
      @api_application.privilege.to_sym
    end

    unregistered do
      # The API is designed to be read-only, at least.
      can(:read, :all)

      # Every application is entitled to be able to lookup UUIDs and make searches
      can(:create, [Endpoints::Uuids::Model::Lookup, Endpoints::Uuids::Model::Bulk])
      can(:create, [Endpoints::Searches::Instance::First, Endpoints::Searches::Instance::All, Endpoints::Searches::Instance::Last])
    end

    # Registered applications can manage all objects that allow it and can have unauthenicated users.
    full do
      can(:manage, :all)
      can(:authenticate, :all)
    end

    # State changes only
    tag_plates do
       can(:create, [Endpoints::StateChanges::Model])
       can(:authenticate, :all)
    end

    def registered?
      @api_application.present?
    end
    private :registered?

    # The decision as to whether the application requires the user to be authenticated is made
    # by the application.  If it does, however, then the user abilities may need to be changed
    # so we need to modify that too.
    def authenticate!(user_ability)
      single_sign_on_cookie = @request.authentication_code
      if single_sign_on_cookie.blank? and cannot?(:authenticate, :nil)
        Core::Service::Authentication::UnauthenticatedError.no_cookie!
      elsif not single_sign_on_cookie.blank?
        user = ::User.find_by(api_key: single_sign_on_cookie) or Core::Service::Authentication::UnauthenticatedError.unauthenticated!
        @request.service.instance_variable_set(:@user, user)
      end

      user_ability.authenticated!
    end
  end
end
