class Api::AssetsController < Api::BaseController
  def children
    respond_to do |format|
      format.json { render :json => @object.children.map(&:list_json) }
    end
  end

  def parents
    respond_to do |format|
      format.json { render :json => @object.parents.map(&:list_json) }
    end
  end

  def holder_quarantine
    # should holder be exposed in the API ?
    # rather than location and container
    respond_to do |format|
      format.json { render :json => @object.holder}
    end
  end
end
