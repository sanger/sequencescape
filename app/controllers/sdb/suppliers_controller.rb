# frozen_string_literal: true
class Sdb::SuppliersController < Sdb::BaseController
  # Show all suppliers
  def index
    @suppliers = Supplier.all
  end

  # Show a supplier
  def show
    @supplier = Supplier.find(params[:id])
  end

  # Create a supplier
  def new
    @supplier = Supplier.new
  end

  def edit
    @supplier = Supplier.find(params[:id])
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

  # Update a supplier
  def update
    @supplier = Supplier.find(params[:id])

    respond_to do |format|
      if @supplier.update(params[:supplier])
        flash[:notice] = 'Supplier was successfully updated'
        format.html { redirect_to(@supplier) }
      else
        format.html { render action: 'new' }
      end
    end
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
