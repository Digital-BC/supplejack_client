
module Supplejack
  class Facet
    
    attr_reader :name
    
    def initialize(name, values)
      @name = name
      @values = values
    end

    def values(sort=nil)
      sort = sort || Supplejack.facets_sort

      array = case sort.try(:to_sym)
              when :index
                @values.sort_by {|k,v| k.to_s }
              when :count
                @values.sort_by {|k,v| -v.to_i }
              else
                @values.to_a
              end

      ActiveSupport::OrderedHash[array]
    end
  end
end
