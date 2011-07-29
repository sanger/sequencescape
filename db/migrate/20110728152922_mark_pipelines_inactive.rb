class MarkPipelinesInactive < ActiveRecord::Migration
  def self.change_active_status(state)
    Pipeline.update_all(
      "active = #{state.inspect.upcase}", [
        'name IN (?)', [
          'MX Library creation',
          'Manual Quality Control',
          'Quality Control'
        ]
      ]
    )
  end

  def self.up
    change_active_status(false)
  end

  def self.down
    change_active_status(true)
  end
end
