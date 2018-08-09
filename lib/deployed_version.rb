# frozen_string_literal: true

module Deployed
  class RepoData
    def tag
      @tag ||= read_file('TAG').strip
    end

    def revision
      @revision ||= read_file('REVISION').strip
    end

    def branch
      @branch ||= read_file('BRANCH').strip
    end

    def release
      @release ||= read_file('RELEASE').strip
    end

    def revision_short
      revision.slice 0..6
    end

    def label
      tag.presence || branch
    end

    def major
      @major ||= version(:major)
    end

    def minor
      @minor ||= version(:minor)
    end

    def extra
      @extra ||= version(:extra)
    end

    def version_hash
      /\Arelease-(?<major>\d+)\.(?<minor>\d+)\.?(?<extra>\S*)\z/.match(label)
    end

    def version_label
      if major == 0 && minor == 0 && extra == 0
        'WIP'
      else
        "#{major}.#{minor}.#{extra}"
      end
    end

    private

    def version(rank)
      version_hash ? version_hash[rank] : 0
    end

    def read_file(filename)
      File.open(Rails.root.join(filename), 'r', &:readline)
    rescue Errno::ENOENT, EOFError
      ''
    end
  end

  ENVIRONMENT = (
    defined?(Rails) && Rails.respond_to?(:env) ? Rails.env :
                           defined?(RAILS_ENV) ? RAILS_ENV :
                              ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] :
                                                 'unknown_environment'
  )

  REPO_DATA = RepoData.new

  VERSION_ID = REPO_DATA.version_label

  APP_NAME = 'Sequencescape'
  RELEASE_NAME = REPO_DATA.release.presence || 'unknown_release'

  MAJOR = REPO_DATA.major
  MINOR = REPO_DATA.minor
  EXTRA = REPO_DATA.extra
  BRANCH = REPO_DATA.label.presence || 'unknown_branch'
  COMMIT = REPO_DATA.revision.presence || 'unknown_revision'
  ABBREV_COMMIT = REPO_DATA.revision_short.presence || 'unknown_revision'

  VERSION_STRING = "#{APP_NAME} #{VERSION_ID} [#{ENVIRONMENT}] #{BRANCH}@#{ABBREV_COMMIT}"

  require 'ostruct'
  DETAILS = OpenStruct.new(
    :name        => APP_NAME,
    :version     => VERSION_ID,
    :environment => ENVIRONMENT
  )
end
