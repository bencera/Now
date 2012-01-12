class RequestsController < ApplicationController
  
  def create
    if ig_logged_in
      @photo = Photo.first(conditions: {ig_media_id: params[:ig_media_id]})
      if params[:type] == 'reply'
        client = Instagram.client(:access_token => current_user.ig_accesstoken)
        client.create_media_comment(params[:ig_media_id], params[:message])
        flash[:notice] = "Your message was sent!"
      elsif params[:type] == 'thanks'
        client = Instagram.client(:access_token => current_user.ig_accesstoken)
        thanks_messages = ["Thanks!", "Thanks a lot!", "Very helpful, thanks!"]
        client.create_media_comment(params[:ig_media_id], thanks_messages[rand(thanks_messages.size)])
        flash[:notice] = "Your thank you message was sent!"
      else
        if @photo.requests.blank?
          @photo.requests.create( :question => params[:question],
                                  :time_asked => Time.now.to_i,
                                  :type => "question",
                                  :user_ids => [current_user.id, Photo.first(conditions: {ig_media_id: params[:ig_media_id]}).user.id] )
          Resque.enqueue(Sendquestion, params[:ig_media_id], current_user.ig_accesstoken, params[:question])
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