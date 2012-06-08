class SitemapController < ApplicationController
  layout nil
  
  def index
    headers['Content-Type'] = 'application/xml'
    latest = Post.last
    if stale?(:etag => latest, :last_modified => latest.updated_at.utc)
      respond_to do |format|
        format.xml { @events = Event.sitemap.trending }
      end
    end
  end
end