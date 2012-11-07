# -*- encoding : utf-8 -*-
module ApplicationHelper
  
  def pageless(total_pages, url=nil, container=nil)
    opts = {
      :totalPages => total_pages,
      :url        => url,
      :loaderMsg  => 'Loading'
    }
    container && opts[:container] ||= container
    javascript_tag("$('#results').pageless(#{opts.to_json});")
  end


end
