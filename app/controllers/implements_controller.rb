class ImplementsController < ApplicationController
  @barcode_prefix = "LE"
  before_filter :find_implement_by_id, :only => [:show, :edit, :update, :destroy]

  def index
    @implements = Implement.find(:all).paginate :per_page => 50, :page => params[:page]
    @barcode_prefix = "LE"

    respond_to do |format|
      format.html
      format.xml  { render :xml => @implements }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml  { render :xml => @implement }
    end
  end

  def new
    @implement = Implement.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @implement }
    end
  end

  def edit
  end

  def create
    @implement = Implement.new(params[:implement])

    respond_to do |format|
      if @implement.save_and_generate_barcode
        flash[:notice] = 'Implement was successfully created.'
        format.html { redirect_to(@implement) }
        format.xml  { render :xml => @implement, :status => :created, :location => @implement }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @implement.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @implement.update_attributes(params[:implement])
        flash[:notice] = 'Implement was successfully updated.'
        format.html { redirect_to(@implement) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @implement.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @implement.destroy

    respond_to do |format|
      format.html { redirect_to(implements_url) }
      format.xml  { head :ok }
    end
  end

  def print_labels
     @implements = Implement.find(:all)
  end

  def print_barcodes
    barcode = BarcodePrinter.new

    printables = []
    count = params[:count].to_i
    params[:printable].each do |key, value|

      equipment = Implement.find(key)
      prefix,n,c =Barcode.split_human_barcode(equipment.barcode)
      label = prefix+equipment.name
      identifier = equipment.id.to_s

      count.times do
        printables.push BarcodeLabel.new({ :number => identifier, :project => label})
      end
    end
    unless printables.empty?
      begin
        printables.sort! {|a,b| a.number <=> b.number }
        barcode.print  printables, params[:printer]
      rescue BarcodeException
        flash[:error] = "Label printing to #{params[:printer]} failed: #{$!}."
      rescue SOAP::FaultError
        flash[:warning] = "There is a problem with the selected printer. Please report it to Systems."
      else
        flash[:notice] = "Your labels have been printed to #{params[:printer]}."
      end
    end

    redirect_to :controller => 'implements', :action => 'print_labels'
  end

  def find_implement_by_id
    @implement = Implement.find(params[:id])
  end

end
