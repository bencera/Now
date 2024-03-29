# -*- encoding : utf-8 -*-
module Geocoder
  class Query
    attr_accessor :text, :options

    def initialize(text, options = {})
      self.text = text
      self.options = options
    end

    def execute
      lookup.search(text, options)
    end

    def to_s
      text
    end

    def sanitized_text
      if coordinates?
        text.split(/\s*,\s*/).join(',')
      else
        text
      end
    end

    ##
    # Get a Lookup object (which communicates with the remote geocoding API)
    # appropriate to the Query text.
    #
    def lookup
      if ip_address?
        name = Configuration.ip_lookup || Geocoder::Lookup.ip_services.first
      else
        name = Configuration.lookup || Geocoder::Lookup.street_services.first
      end
      Lookup.get(name)
    end

    ##
    # Is the Query text blank? (ie, should we not bother searching?)
    #
    def blank?
      !!text.to_s.match(/^\s*$/)
    end

    ##
    # Does the Query text look like an IP address?
    #
    # Does not check for actual validity, just the appearance of four
    # dot-delimited numbers.
    #
    def ip_address?
      !!text.to_s.match(/^(::ffff:)?(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)
    end

    ##
    # Is the Query text a loopback IP address?
    #
    def loopback_ip_address?
      !!(text == "0.0.0.0" or text.to_s.match(/^127/))
    end

    ##
    # Does the given string look like latitude/longitude coordinates?
    #
    def coordinates?
      text.is_a?(Array) or (
        text.is_a?(String) and
        !!text.to_s.match(/^-?[0-9\.]+, *-?[0-9\.]+$/)
      )
    end

    ##
    # Return the latitude/longitude coordinates specified in the query,
    # or nil if none.
    #
    def coordinates
      sanitized_text.split(',') if coordinates?
    end

    ##
    # Should reverse geocoding be performed for this query?
    #
    def reverse_geocode?
      coordinates?
    end
  end
end
