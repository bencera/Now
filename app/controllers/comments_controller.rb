# -*- encoding : utf-8 -*-
class CommentsController < ApplicationController
  
  def create  
    @photo = Photo.find(params[:photo_id])  
    @comment = @photo.comments.create!(params[:comment])
    @user = User.find(params[:comment]["user"])
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end  
end
