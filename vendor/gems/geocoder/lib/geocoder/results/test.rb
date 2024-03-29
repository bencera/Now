# -*- encoding : utf-8 -*-
require 'geocoder/results/base'

module Geocoder
  module Result
    class Test < Base

      %w[latitude longitude city state state_code province
      province_code postal_code country country_code address].each do |attr|
        define_method(attr) do
          @data[attr.to_s] || @data[attr.to_sym]
        end
      end
    end
  end
end
