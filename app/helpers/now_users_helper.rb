# -*- encoding : utf-8 -*-
module NowUsersHelper

  def self.find_or_create_device(params={})
    
    device = APN::Device.where(:udid => params[:deviceid]).first ||  APN::Device.create!(:udid => params[:deviceid])

    save_device = false
  
    if params[:longitude] && params[:latitude]
      device.inc(:visits, 1)
      Rails.logger.info("New visits #{device.visits}")
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
end
