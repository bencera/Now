# -*- encoding : utf-8 -*-
module NowUsersHelper

  def self.find_or_create_device(params={})
    
    device = APN::Device.where(:udid => params[:deviceid]).first ||  APN::Device.create!(:udid => params[:deviceid])

    save_device = false
  
    if params[:longitude] && params[:latitude]
      device.coordinates = [params[:longitude].to_f,params[:latitude].to_f] 
      save_device = true
    end
    
    if params[:token] && !(device.subscriptions.where(:token => params[:token]).first) 
      device.subscriptions.create(:application => APN::Application.first, :token => params[:token])
      save_device = false
    end

    device.save if save_device

    return device
  end

  def self.set_super_user(email, params={})
    user = FacebookUser.where(:email => email).first
    if user.nil?
      puts "Invalid email -- #{email} not in our system" 
      return
    end

    user.super_user = true
    user.save!
  end

  def self.set_ig_username(email, ig_username, params={})
    user = FacebookUser.where(:email => email).first
    
    if user.nil?
      puts "Invalid email -- #{email} not in our system" 
      return
    end

    if ig_username.blank?
      puts "bad ig_username"
      return
    end

    user.ig_username = ig_username
    user.save!

  end
  
  def self.set_ig_user_id(email, ig_user_id, params={})
    user = FacebookUser.where(:email => email).first
    if user.nil?
      puts "Invalid email -- #{email} not in our system" 
      return
    end

    if ig_user_id.blank?
      puts "bad ig_user_id"
      return
    end

    user.ig_user_id = ig_user_id
    user.save!
  end

end
