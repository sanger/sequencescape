module DownloadHelpers
  TIMEOUT = 5
  PATH    = Rails.root.join("tmp/downloads")

  extend self

  def downloads
    Dir[PATH.join("*")]
  end

  def downloaded_file(file)
    wait_for_download
    File.read(PATH.join(file))
  end

  def wait_for_download
    Timeout.timeout(TIMEOUT) do
      sleep 0.5 until downloaded?
    end
  end

  def downloaded?
    !downloading? && downloads.any?
  end

  def downloading?
    downloads.grep(/\.part$/).any?
  end

  def remove_downloads
    FileUtils.rm_f(downloads)
  end
end
