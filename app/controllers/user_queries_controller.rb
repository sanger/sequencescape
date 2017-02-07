class UserQueriesController < ApplicationController

  def new
    @user_query = UserQuery.new(url: request.referrer)
  end

  def create
    @user_query = UserQuery.new(user_query_params.merge(user: current_user))
    if @user_query.valid?
      UserQueryMailer.request_for_help(@user_query).deliver
      flash[:notice] = 'Thank you for your request. We will contact you shortly'
      redirect_to new_user_query_path
    else
      flash.now[:error] = @user_query.errors.full_messages
      render :new
    end
  end

  def user_query_params
    params.require(:user_query).permit(:user_name, :url, :what_was_trying_to_do, :what_happened, :what_expected)
  end

end