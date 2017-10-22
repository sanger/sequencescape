# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Sdb::SuppliersController < Sdb::BaseController
  # Show all suppliers
  def index
    @suppliers = Supplier.all
  end

  # Create a supplier
  def new
    @supplier = Supplier.new
  end

  # Create a supplier
  def create
    @supplier = Supplier.new(params[:supplier])

    respond_to do |format|
      if @supplier.save
        flash[:notice] = 'Supplier was successfully created.'
        format.html { redirect_to('/sdb/') }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def edit
    @supplier = Supplier.find(params[:id])
  end

  # Update a supplier
  def update
    @supplier = Supplier.find(params[:id])

    respond_to do |format|
      if @supplier.update_attributes(params[:supplier])
        flash[:notice] = 'Supplier was successfully updated'
        format.html { redirect_to(@supplier) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # Show a supplier
  def show
    @supplier = Supplier.find(params[:id])
  end

  def sample_manifests
    @supplier = Supplier.find(params[:id])
    @sample_manifests = @supplier.sample_manifests.paginate(page: params[:page])
  end

  def studies
    @supplier = Supplier.find(params[:id])
    @studies = @supplier.studies.paginate(page: params[:page])
  end
end
