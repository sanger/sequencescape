
class PicoDilutionsController < ApplicationController
  before_action :login_required, except: [:index]

  def index
    pico_dilutions = DilutionPlate.with_pico_children.for_pico_view.page(params[:page]).order(id: :desc).per_page(500)
    pico_dilutions_hash = PicoDilutionPlate.index_to_hash(pico_dilutions)

    respond_to do |format|
      format.xml  { render xml: pico_dilutions_hash, root: 'records' }
      format.json { render json: pico_dilutions_hash }
    end
  end
end
