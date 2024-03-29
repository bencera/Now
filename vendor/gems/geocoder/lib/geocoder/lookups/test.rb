# -*- encoding : utf-8 -*-
require 'geocoder/lookups/base'
require 'geocoder/results/test'

module Geocoder
  module Lookup
    class Test < Base

      def self.add_stub(query_text, results)
        stubs[query_text] = results
      end

      def self.read_stub(query_text)
        stubs.fetch(query_text) {
          raise ArgumentError, "unknown stub request #{query_text}"
        }
      end

      def self.stubs
        @stubs ||= {}
      end

      def self.reset
        @stubs = {}
      end

      private

      def results(query)
        Geocoder::Lookup::Test.read_stub(query.text)
      end

    end
  end
end
