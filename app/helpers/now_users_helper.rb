# -*- encoding : utf-8 -*-
module NowUsersHelper

  def self.find_or_create_device(params={})
    
    device = APN::Device.where(:udid => params[:deviceid]).first ||  APN::Device.create!(:udid => params[:deviceid])
  
    if params[:token] && !(device.subscriptions.where(:token => params[:token]).first) 
      device.subscriptions.create(:application => APN::Application.first, :token => params[:token])
    end

    return device
  end
end
