# -*- encoding : utf-8 -*-
module Geocoder
  module Sql
    extend self

    ##
    # Distance calculation for use with a database that supports POWER(),
    # SQRT(), PI(), and trigonometric functions SIN(), COS(), ASIN(),
    # ATAN2(), DEGREES(), and RADIANS().
    #
    # Based on the excellent tutorial at:
    # http://www.scribd.com/doc/2569355/Geo-Distance-Search-with-MySQL
    #
    def full_distance(latitude, longitude, lat_attr, lon_attr, options = {})
      earth = Geocoder::Calculations.earth_radius(options[:units] || :mi)

      "#{earth} * 2 * ASIN(SQRT(" +
        "POWER(SIN((#{latitude.to_f} - #{lat_attr}) * PI() / 180 / 2), 2) + " +
        "COS(#{latitude.to_f} * PI() / 180) * COS(#{lat_attr} * PI() / 180) * " +
        "POWER(SIN((#{longitude.to_f} - #{lon_attr}) * PI() / 180 / 2), 2)" +
      "))"
    end

    ##
    # Distance calculation for use with a database without trigonometric
    # functions, like SQLite. Approach is to find objects within a square
    # rather than a circle, so results are very approximate (will include
    # objects outside the given radius).
    #
    # Distance and bearing calculations are *extremely inaccurate*. To be
    # clear: this only exists to provide interface consistency. Results
    # are not intended for use in production!
    #
    def approx_distance(latitude, longitude, lat_attr, lon_attr, options = {})
      dx = Geocoder::Calculations.longitude_degree_distance(30, options[:units] || :mi)
      dy = Geocoder::Calculations.latitude_degree_distance(options[:units] || :mi)

      # sin of 45 degrees = average x or y component of vector
      factor = Math.sin(Math::PI / 4)

      "(#{dy} * ABS(#{lat_attr} - #{latitude.to_f}) * #{factor}) + " +
        "(#{dx} * ABS(#{lon_attr} - #{longitude.to_f}) * #{factor})"
    end

    def within_bounding_box(sw_lat, sw_lng, ne_lat, ne_lng, lat_attr, lon_attr)
      spans = "#{lat_attr} BETWEEN #{sw_lat} AND #{ne_lat} AND "
      # handle box that spans 180 longitude
      if sw_lng.to_f > ne_lng.to_f
        spans + "#{lon_attr} BETWEEN #{sw_lng} AND 180 OR " +
        "#{lon_attr} BETWEEN -180 AND #{ne_lng}"
      else
        spans + "#{lon_attr} BETWEEN #{sw_lng} AND #{ne_lng}"
      end
    end

    ##
    # Fairly accurate bearing calculation. Takes a latitude, longitude,
    # and an options hash which must include a :bearing value
    # (:linear or :spherical).
    #
    # Based on:
    # http://www.beginningspatial.com/calculating_bearing_one_point_another
    #
    def full_bearing(latitude, longitude, lat_attr, lon_attr, options = {})
      case options[:bearing]
      when :linear
        "CAST(" +
          "DEGREES(ATAN2( " +
            "RADIANS(#{lon_attr} - #{longitude.to_f}), " +
            "RADIANS(#{lat_attr} - #{latitude.to_f})" +
          ")) + 360 " +
        "AS decimal) % 360"
      when :spherical
        "CAST(" +
          "DEGREES(ATAN2( " +
            "SIN(RADIANS(#{lon_attr} - #{longitude.to_f})) * " +
            "COS(RADIANS(#{lat_attr})), (" +
              "COS(RADIANS(#{latitude.to_f})) * SIN(RADIANS(#{lat_attr}))" +
            ") - (" +
              "SIN(RADIANS(#{latitude.to_f})) * COS(RADIANS(#{lat_attr})) * " +
              "COS(RADIANS(#{lon_attr} - #{longitude.to_f}))" +
            ")" +
          ")) + 360 " +
        "AS decimal) % 360"
      end
    end

    ##
    # Totally lame bearing calculation. Basically useless except that it
    # returns *something* in databases without trig functions.
    #
    def approx_bearing(latitude, longitude, lat_attr, lon_attr, options = {})
      "CASE " +
        "WHEN (#{lat_attr} >= #{latitude.to_f} AND " +
          "#{lon_attr} >= #{longitude.to_f}) THEN  45.0 " +
        "WHEN (#{lat_attr} <  #{latitude.to_f} AND " +
          "#{lon_attr} >= #{longitude.to_f}) THEN 135.0 " +
        "WHEN (#{lat_attr} <  #{latitude.to_f} AND " +
          "#{lon_attr} <  #{longitude.to_f}) THEN 225.0 " +
        "WHEN (#{lat_attr} >= #{latitude.to_f} AND " +
          "#{lon_attr} <  #{longitude.to_f}) THEN 315.0 " +
      "END"
    end
  end
end
