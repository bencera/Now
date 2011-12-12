class RequestsController < ApplicationController
  
  def create
    question = Request.new.find_question(params[:question_id].to_i, params[:venue_name])
    media = Instagram.media_item(params[:ig_media_id], :access_token => current_user.ig_accesstoken)
    count = media.comments["count"].to_i
    photo_user_id = media.user.id
    Instagram.create_media_comment(params[:ig_media_id], question, :access_token => current_user.ig_accesstoken )
    Instagram.like_media(params[:ig_media_id], :access_token => current_user.ig_accesstoken )
    Photo.first(conditions: {ig_media_id: params[:ig_media_id]}).requests.create( :question => question,
                                                                                  :time_asked => Time.now.to_i,
                                                                                  :media_comment_count => count, 
                                                                                  :type => "question", 
                                                                                  :user_ids => [current_user.id, photo_user_id] )
    Resque.enqueue(CheckAnswer, params[:ig_media_id], count, photo_user_id, current_user.ig_accesstoken)
    flash[:notice] = "Your question was succesfully asked!"
    redirect_to :back
  end
  
  def show
    
  end
  
  def index
    @requests = Request.where(:user_ids => current_user.id)
  end
end
