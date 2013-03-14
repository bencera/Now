# -*- encoding : utf-8 -*-
class LogBadFbCreate
  @queue = :error

  def self.perform(params)
    raise "fb user didn't create properly"
  end
end

