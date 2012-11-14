# -*- encoding : utf-8 -*-
class LogBadFbCreate
  @queue = :bad_fb_create_queue

  def self.perform(params)
    raise "fb user didn't create properly"
  end
end

