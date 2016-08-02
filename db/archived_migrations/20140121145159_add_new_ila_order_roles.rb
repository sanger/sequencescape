#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddNewIlaOrderRoles < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      each_role do |role|
        Order::OrderRole.create!(:role=>role)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_role do |role|
        Order::OrderRole.find_by_role(role).destroy
      end
    end
  end

  def self.each_role
    ['ILA ISC','ILA WGS'].each do |role|
      yield role
    end
  end
end
