# -*- encoding : utf-8 -*-
class SitemapController < ApplicationController
  layout nil
  
  def index
    headers['Content-Type'] = 'application/xml'
    latest = Event.last
    if stale?(:etag => latest, :last_modified => Time.at(latest.end_time.to_i))
      respond_to do |format|
        format.xml { @events = Event.where(:status.in => ["trending", "trended"]).limit(50000) }
      end
    end
  end
end
