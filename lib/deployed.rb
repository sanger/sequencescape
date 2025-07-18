# frozen_string_literal: true

require 'open3'

module Deployed
  class RepoData
    def tag
      @tag ||= git_tag || read_file('TAG').strip.presence
    end

    def revision
      @revision ||= git_rev || read_file('REVISION').strip.presence
    end

    def branch
      @branch ||= git_branch || read_file('BRANCH').strip.presence
    end

    def release
      @release ||= read_file('RELEASE').strip
    end

    def release_url
      @release_url ||= read_file('REPO').strip
    end

    # Return the time of the release as a modified ISO 8601 string.
    # If the release name is a 14 digit string (e.g. 20231025123000), it is assumed to be a timestamp.
    def release_timestamp
      return unless release.match?(/^\d{14}$/)

      DateTime.strptime(release, '%Y%m%d%H%M%S').strftime('%FT%H:%M:%S')
    end

    def revision_short
      @revision_short ||= revision&.slice 0..6
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

    def patch
      @patch ||= version(:patch)
    end

    def extra
      @extra ||= version(:extra)
    end

    def version_hash
      @version_hash ||= /\Av(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(?<extra>\S*)/.match(label)
    end

    def version_label
      major == 0 && minor == 0 && patch == 0 ? 'WIP' : "#{major}.#{minor}.#{patch}"
    end

    private

    def git_tag
      cmd = 'git tag -l --points-at HEAD --sort -version:refname | head -1'
      @git_tag ||= execute_command(cmd)
    end

    def git_rev
      cmd = 'git rev-parse HEAD'
      @git_rev ||= execute_command(cmd)
    end

    def git_branch
      cmd = 'git rev-parse --abbrev-ref HEAD'
      @git_branch ||= execute_command(cmd)
    end

    def version(rank)
      version_hash ? version_hash[rank] : '0'
    end

    def execute_command(cmd)
      _stdin, stdout, _stderr, _wait_thr = Open3.popen3(cmd)
      res = stdout.gets
      res&.strip
    end

    def read_file(filename)
      Rails.root.join(filename).open('r', &:readline)
    rescue Errno::ENOENT, EOFError
      ''
    end
  end

  ENVIRONMENT = Rails.env

  REPO_DATA = RepoData.new

  VERSION_ID = REPO_DATA.version_label

  APP_NAME = 'Sequencescape'
  RELEASE_NAME = REPO_DATA.release.presence || 'LOCAL'
  RELEASE_TIMESTAMP = REPO_DATA.release_timestamp

  MAJOR = REPO_DATA.major
  MINOR = REPO_DATA.minor
  PATCH = REPO_DATA.patch
  EXTRA = REPO_DATA.extra
  BRANCH = REPO_DATA.label.presence || 'unknown_branch'
  COMMIT = REPO_DATA.revision.presence || 'unknown_revision'
  ABBREV_COMMIT = REPO_DATA.revision_short.presence || 'unknown_revision'

  VERSION_STRING = "#{APP_NAME} #{VERSION_ID} [#{ENVIRONMENT}]".freeze
  VERSION_COMMIT = "#{BRANCH}@#{ABBREV_COMMIT}".freeze
  REPO_URL = REPO_DATA.release_url.presence || '#'
  HOSTNAME = Socket.gethostname

  require 'ostruct'

  DETAILS = OpenStruct.new(name: nil, version: VERSION_ID, environment: ENVIRONMENT) # rubocop:todo Style/OpenStructUse
end
