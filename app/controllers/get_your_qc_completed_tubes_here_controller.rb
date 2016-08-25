class GetYourQcCompletedTubesHereController < ApplicationController

  before_filter :login_required

  def new
  end

  def create
    @generator = LibPoolNormTubeGenerator.new(params[:barcode], current_user, Study.find_by_name("Lib PCR-XP QC Completed Tubes"))
    if @generator.valid?
      if @generator.create!
        binding.pry
        flash[:notice] = "QC Completed tubes successfully created for #{@generator.plate.sanger_human_barcode}. Go celebrate!"
        redirect_to study_asset_groups_path(@generator.study.id)
      else
        flash[:error] = "Oh dear, your tubes weren't created. It's not you its me so please contact PSD."
        render :new
      end
    else
      flash[:error] = @generator.errors.full_messages.join(", ")
      render :new
    end
  end
  
end