class Photo

  attr_accessor :id, :location, :place
  attr_writer :contents

  def initialize params={}
    @id = params[:_id].to_s if !params[:_id].nil?
    @location = (params[:metadata] && params[:metadata][:location]) ? Point.new(params[:metadata][:location]) : nil
    @place = params[:metadata] && params[:metadata][:place] ? params[:metadata][:place] : nil
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

  def persisted?
    !@id.nil?
  end

  def save
    if !persisted?
      gps = EXIFR::JPEG.new(@contents).gps
      @location = Point.new({:lat => gps.latitude, :lng => gps.longitude})
      @contents.rewind
      description={}
      description[:content_type] = "image/jpeg"
      description[:metadata] = {}
      description[:metadata][:location]=@location.to_hash if !@location.nil?
      description[:metadata][:place] = BSON::ObjectId.from_string(@place.to_s) if !@place.nil?
      grid_file = Mongo::Grid::File.new(@contents.read, description )
      id=self.class.mongo_client.database.fs.insert_one(grid_file)
      @id=id.to_s
      Rails.logger.debug {"saved gridfs file #{id}"}
      @id
    else
      doc = self.class.mongo_client.database.fs.find(:_id=>BSON::ObjectId(@id)).first
      doc[:metadata][:location] = @location.to_hash if !@location.nil?
      doc[:metadata][:place] = BSON::ObjectId.from_string(@place.to_s) if !@place.nil?
      self.class.mongo_client.database.fs.find(:_id=>BSON::ObjectId(@id)).update_one(doc)
      doc = self.class.mongo_client.database.fs.find(:_id=>BSON::ObjectId(@id)).first
    end
  end

  def self.all (skip=0,limit=0)
    photos = []
    self.mongo_client.database.fs.find().skip(skip).limit(limit).to_a.map {|doc|
      photos << Photo.new(doc)
    }
    return photos
  end

  def self.find id
    doc = self.mongo_client.database.fs.find(:_id=>BSON::ObjectId(id)).first
    return doc.nil? ? nil : Photo.new(doc)
  end

  def contents
    f=self.class.mongo_client.database.fs.find_one(:_id => BSON::ObjectId(@id))
    if f
      buffer = ""
      f.chunks.reduce([]) do |x,chunk|
        buffer << chunk.data.data
      end
      return buffer
    end
  end

  def destroy
    self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId(@id)).delete_one
  end

  def find_nearest_place_id max_distance
    Place.near(@location,max_distance).limit(1).projection(:_id=>1).map {|r| r[:_id]}[0]
  end

  def place
    Place.find(@place.to_s) if !@place.nil?
  end
  def place=(place)
    if place.class == Place
      @place = BSON::ObjectId.from_string(place.id.to_s)
    elsif place.class == String
      @place = BSON::ObjectId.from_string(place)
    else
      @place = place
    end
  end

  def self.find_photos_for_place place_id
    self.mongo_client.database.fs.find({:'metadata.place'=>BSON::ObjectId.from_string(place_id.to_s)})
  end

end