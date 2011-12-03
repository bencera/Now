class UserMailer < ActionMailer::Base
  default from: "ben@ubimachine.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.question_answered.subject
  #
  def question_answered(user)
    @user = user
    #... send email to user telling him that his question was answered

    mail to: "to@example.org"
  end
end
