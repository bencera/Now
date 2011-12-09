class RequestsController < ApplicationController
  
  def create
    question = Request.new.find_question(params[:question_id], params[:venue_name])
    media = Instagram.media_item(params[:ig_media_id], :access_token => session[:access_token])
    count = media.comments["count"].to_i
    photo_user_id = media.user.id
    Photo.first(conditions: {ig_media_id: params[:ig_media_id]}).requests.create(:question => params[:question], :media_comment_count => count, :type => "question")
    Instagram.create_media_comment(params[:ig_media_id], params[:question], :access_token => session[:access_token] )
    Delayed::Job.enqueue(Checkcommentanswer.new(params[:ig_media_id], count, photo_user_id, session[:access_token]))
    redirect_to :back
  end
end
