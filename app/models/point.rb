class Point

  attr_accessor :longitude, :latitude

  def initialize(hash={})
    if !hash[:lng] && !hash[:lat]
      @longitude =  -1.8625303
      @latitude = 53.82856035
    else
      @longitude = hash[:lng]
      @latitude = hash[:lat]
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