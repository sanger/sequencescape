
class Api::AssetsController < Api::BaseController
  def children
    respond_to do |format|
      format.json { render json: @object.children.map(&:list_json) }
    end
  end

  def parents
    respond_to do |format|
      format.json { render json: @object.parents.map(&:list_json) }
    end
  end
end
