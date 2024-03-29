# -*- encoding : utf-8 -*-
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
          @question = params[:question]
          Resque.enqueue(Sendquestion, params[:ig_media_id], current_user.ig_accesstoken, params[:question])
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


  def comment
      client = Instagram.client(:access_token => "1200123.6c3d78e.0d51fa6ae5c54f4c99e00e85df38c435")
      comment = "@#{params[:username]} #{params[:comment]}"
      client.create_media_comment(params[:ig_media_id], comment)
      $redis.incr("instagram_responses")
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
