class RequestsController < ApplicationController
  
  def create
    if ig_logged_in
      @photo = Photo.first(conditions: {ig_media_id: params[:ig_media_id]})
      if params[:type] == 'reply'
        Instagram.create_media_comment(params[:ig_media_id], params[:message], :access_token => current_user.ig_accesstoken)
        flash[:notice] = "Your message was sent!"
      elsif params[:type] == 'thanks'
        thanks_messages = ["Thanks!", "Thanks a lot!", "Very helpful, thanks!"]
        Instagram.create_media_comment(params[:ig_media_id], thanks_messages[rand(thanks_messages.size)], :access_token => current_user.ig_accesstoken)
        flash[:notice] = "Your thank you message was sent!"
      else
        if Photo.first(conditions: {ig_media_id: params[:ig_media_id]}).requests.blank?
          question = params[:question] #Request.new.find_question(params[:question_id].to_i, params[:venue_name])
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
          Resque.enqueue(Checkanswer, params[:ig_media_id], count, photo_user_id, current_user.ig_accesstoken)
          if current_user.email.nil?
            flash.now[:notice] = "Your question was succesfully asked! Tell us your email in Settings to get notified when it's answered."
          else
            flash.now[:notice] = "Your question was succesfully asked! We will send you an email when it's answered."
          end
        else
          flash.now[:notice] = "Sorry, somebody already asked a question on this photo.. Try another one!"
        end
      end
    else
      flash.now[:notice] = "You must be logged in to ask a question!"
    end
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end
  
  def show
    
  end
  def index
    require 'will_paginate/array'
    if ig_logged_in
      requests = Request.where(user_ids: current_user.id).order_by([[:time_asked, :desc]])
      @requests = requests.paginate(:per_page => 5, :page => params[:page])
    else
      @requests = Request.all.paginate(:per_page => 5, :page => params[:page])
    end
  end
  
  def ask
    @photo = Photo.first(conditions: {_id: params[:id]})
  end
end