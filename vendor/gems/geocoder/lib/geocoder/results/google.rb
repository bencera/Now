# -*- encoding : utf-8 -*-
require 'geocoder/results/base'

module Geocoder::Result
  class Google < Base

    def coordinates
      ['lat', 'lng'].map{ |i| geometry['location'][i] }
    end

    def address(format = :full)
      formatted_address
    end

    def city
      fields = [:locality, :sublocality,
        :administrative_area_level_3,
        :administrative_area_level_2]
      fields.each do |f|
        if entity = address_components_of_type(f).first
          return entity['long_name']
        end
      end
      return nil # no appropriate components found
    end

    def state
      if state = address_components_of_type(:administrative_area_level_1).first
        state['long_name']
      end
    end

    def state_code
      if state = address_components_of_type(:administrative_area_level_1).first
        state['short_name']
      end
    end

    def country
      if country = address_components_of_type(:country).first
        country['long_name']
      end
    end

    def country_code
      if country = address_components_of_type(:country).first
        country['short_name']
      end
    end

    def postal_code
      if postal = address_components_of_type(:postal_code).first
        postal['long_name']
      end
    end

    def types
      @data['types']
    end

    def formatted_address
      @data['formatted_address']
    end

    def address_components
      @data['address_components']
    end

    ##
    # Get address components of a given type. Valid types are defined in
    # Google's Geocoding API documentation and include (among others):
    #
    #   :street_number
    #   :locality
    #   :neighborhood
    #   :route
    #   :postal_code
    #
    def address_components_of_type(type)
      address_components.select{ |c| c['types'].include?(type.to_s) }
    end

    def geometry
      @data['geometry']
    end

    def precision
      geometry['location_type'] if geometry
    end
  end
end
