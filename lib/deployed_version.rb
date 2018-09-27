# frozen_string_literal: true

require 'open3'

module Deployed
  class RepoData
    def tag
      @tag ||= get_git_tag || read_file('TAG').strip.presence
    end

    def revision
      @revision ||= get_git_rev || read_file('REVISION').strip.presence
    end

    def branch
      @branch ||= get_git_branch || read_file('BRANCH').strip.presence
    end

    def release
      @release ||= read_file('RELEASE').strip
    end

    def release_url
      @release_url ||= read_file('REPO').strip
    end

    def revision_short
      @revision_short ||= revision.slice 0..6
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
      @version_hash ||= /\Arelease-(?<major>\d+)\.(?<minor>\d+)\.?(?<extra>\S*)\z/.match(label)
    end

    def version_label
      if major == 0 && minor == 0 && extra == 0
        'WIP'
      else
        "#{major}.#{minor}.#{extra}"
      end
    end

    private

    def get_git_tag
      cmd = 'git tag -l --points-at HEAD --sort -version:refname | head -1'
      @git_tag ||= execute_command(cmd)
    end

    def get_git_rev
      cmd = 'git rev-parse HEAD'
      @git_rev ||= execute_command(cmd)
    end

    def get_git_branch
      cmd = 'git rev-parse --abbrev-ref HEAD'
      @git_branch ||= execute_command(cmd)
    end

    def version(rank)
      version_hash ? version_hash[rank] : 0
    end

    def execute_command(cmd)
      _stdin, stdout, _stderr, _wait_thr = Open3.popen3(cmd)
      stdout.gets
    end

    def read_file(filename)
      File.open(Rails.root.join(filename), 'r', &:readline)
    rescue Errno::ENOENT, EOFError
      ''
    end
  end

  ENVIRONMENT = Rails.env

  REPO_DATA = RepoData.new

  VERSION_ID = REPO_DATA.version_label

  APP_NAME = 'Sequencescape'
  RELEASE_NAME = REPO_DATA.release.presence || 'LOCAL'

  MAJOR = REPO_DATA.major
  MINOR = REPO_DATA.minor
  EXTRA = REPO_DATA.extra
  BRANCH = REPO_DATA.label.presence || 'unknown_branch'
  COMMIT = REPO_DATA.revision.presence || 'unknown_revision'
  ABBREV_COMMIT = REPO_DATA.revision_short.presence || 'unknown_revision'

  VERSION_STRING = "#{APP_NAME} #{VERSION_ID} [#{ENVIRONMENT}]"
  VERSION_COMMIT = "#{BRANCH}@#{ABBREV_COMMIT}"
  REPO_URL       = REPO_DATA.release_url.presence || '#'
  HOSTNAME       = Socket.gethostname

  require 'ostruct'
  DETAILS = OpenStruct.new(
    :name        => APP_NAME,
    :version     => VERSION_ID,
    :environment => ENVIRONMENT
  )
end
