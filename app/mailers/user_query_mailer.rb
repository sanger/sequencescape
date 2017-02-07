class UserQueryMailer < ActionMailer::Base

  def request_for_help(user_query)
    @user_query = user_query
    @from = user_query.from
    @to = user_query.to
    @subject = "Request for help from #{user_query.user_name}"
    @date = user_query.date
    mail(
      from: @from,
      to: @to,
      subject: @subject,
      sent_on: @date
    )
  end

end