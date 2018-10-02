class Health
  attr_reader :status, :message

  def initialize
    @status, @message = :ok, []
    check
  end

  def check
    @message << 'No problems detected.' if status == :ok
  end
end
