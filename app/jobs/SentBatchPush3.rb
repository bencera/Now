# -*- encoding : utf-8 -*-
class SendBatchPush3
  @queue = :sendpush
  def self.perform(in_params="{}")

    params = eval(in_params)

    event_id = params[:event_id].to_s
    device_ids = params[:device_ids]
    user_ids = params[:facebook_user_ids]
    message = params[:message]
    reengagement = params[:reengagement]
    test = params[:test]
    first_batch = params[:first_batch]
    total_count = params[:total_count]
    ab_test_id = params[:ab_test_id]
    is_a = params[:is_a]
    type = params[:type] 

    event = Event.find(event_id)
    devices = APN::Device.find(device_ids)
    users = APN::Device.where(:now_id.in => user_ids) if user_ids

    return if event.nil?

    users.each {|fb_user| SentPush.notify_user(message. event_id, fb_user, :type => type, 
                                               :ab_test_id => ab_test_id, :is_a => is_a,
                                               :reengagement => options[:reengagement],
                                               :test => test)}

    devices.each {|device| SentPush.notify_device(message. event_id, device, :type => type, 
                                                  :ab_test_id => ab_test_id, :is_a => is_a,
                                                  :reengagement => options[:reengagement],
                                                  :test => test)}

  end
end

