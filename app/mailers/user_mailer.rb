class UserMailer < ActionMailer::Base
  default from: "ubimachine <ben@ubimachine.com>" #a verifier

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.question_answered.subject
  #
  def question_answered(user, ig_media_id)
    @user = user
    @request = Request.where(:photo_id => Photo.where(:ig_media_id => ig_media_id).first.id).first
    #... send email to user telling him that his question was answered

    mail to: @user.email, subject: "Your question on #{@request.photo.venue.name} has been answered"
  end
  
  def trending(trending_venues)
    
    @trending_venues = trending_venues
    mail to: "ben.broca@gmail.com", subject: "Venue trending"
    
  end
  
end