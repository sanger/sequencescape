# NOTE[xxx]: This controller may not be required but is here to support the Javascript used in the
# library prep pipeline.
class Pipelines::AssetsController < ApplicationController
  def new
    @asset, @family = Asset.new, Family.find(params[:family])
    render :partial => 'descriptor', :locals => { :field => Descriptor.new, :field_number => params[:id] }
  end
end
