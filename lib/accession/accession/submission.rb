module Accession
  class Submission
    
    include ActiveModel::Model
    include Accessionable

    attr_reader :user, :sample

    validates_presence_of :user, :sample

    def initialize(user, sample)
      @user = user
      @sample = sample
    end
  end
end