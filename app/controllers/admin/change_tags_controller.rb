class Admin::ChangeTagsController < ApplicationController
  before_filter :admin_login_required, :only => [:lookup, :update, :index]

  def index
  end

  def lookup
    @change_tag = ChangeTag.new(params[:change_tags])

    respond_to do |format|
      begin
        @change_tag.validate!
      rescue ChangeTagException::MissingTag
        format.html do
          flash[:errors] = 'Missing tags'
          redirect_to(change_tags_path) and return
        end
      rescue ChangeTagException::MissingLibraryTube
        format.html do
          flash[:errors] = 'Couldnt find library tubes'
          redirect_to(change_tags_path) and return
        end
      end

      format.html
    end

  end

  def bulk_update
    ChangeTag.update_tags(params[:change_tags][:library_tubes])
    respond_to do |format|
      format.html do
        flash[:notice] = "Updated tags"
        redirect_to(change_tags_path)
      end
    end
  end

end
