class Pipeline::GroupByHolderOnly
  include Pipeline::Grouper

  def call(conditions, variables, group)
    conditions << "tca.container_id=?"
    variables  << group.to_i
  end
  private :call

  def grouping
    'tca.container_id'
  end
  private :grouping
end
