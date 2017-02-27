# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

class AddProductToExistingOrdersByRole < ActiveRecord::Migration
  class Order < ActiveRecord::Base
    self.table_name = ('orders')
    belongs_to :order_role
    scope :with_role, ->(role) { where(order_role_id: role.id) }
  end

  class OrderRole < ActiveRecord::Base
    self.table_name = ('order_roles')
  end

  ORDER_ROLE_PRODUCT = {
    'PATH'     => 'PWGS',
    'ILB PATH' => 'PWGS',
    'HWGS'     => 'MWGS',
    'ILB HWGS' => 'MWGS',
    'ILA ISC'  => 'ISC',
    'ILA WGS'  => 'MWGS',
    'HSqX'     => 'HSqX',
    'ReISC'    => 'ReISC',
    'PWGS'     => 'PWGS',
    'MWGS'     => 'MWGS',
    'ISC'      => 'ISC'
  }

  def self.up
    ActiveRecord::Base.transaction do
      say 'Setting for roles...'
      ORDER_ROLE_PRODUCT.each do |rolename, product_name|
        role = OrderRole.find_by(role: rolename)
        next if role.nil?
        product = Product.find_by!(name: product_name)
        say "#{rolename} to #{product_name}"
        Order.with_role(role).update_all(product_id: product.id)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Request.update_all(product_id: nil)
    end
  end
end
