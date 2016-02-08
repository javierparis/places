class Point

  attr_accessor :longitude, :latitude

  def initialize(hash={})
    if hash
      if hash[:type] #in GeoJSON Point format
        @longitude = hash[:coordinates][0]
        @latitude = hash[:coordinates][1]
      else #in legacy format
        @latitude = hash[:lat]
        @longitude = hash[:lng]
      end
    end
  end

  def to_hash
    # GeoJSON Point format
    # {"type":"Point", "coordinates":[ -1.8625303, 53.8256035]}
    {
      :type => 'Point',
      :coordinates => [@longitude, @latitude]
    }
  end

end