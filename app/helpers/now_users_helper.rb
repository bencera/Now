# -*- encoding : utf-8 -*-
module NowUsersHelper

  def self.find_or_create_device(params={})
    
    device = APN::Device.where(:udid => params[:deviceid]).firstA ||  APN::Device.create!(:udid => params[:deviceid])
  
    if !(d.subscriptions.where(:token => params[:token]).first) && params[:token]
      device.subscriptions.create(:application => APN::Application.first, :token => params[:token])
    end

    return device
  end
end
