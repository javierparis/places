class Place

  attr_accessor :id, :formatted_address, :location, :address_components

  def initialize(params={})
    @id = params[:_id].to_s if params[:_id]
    @formatted_address = params[:formatted_address]
    @location = Point.new(params['geometry.geolocation'])
    @address_components = []
    params[:address_components].each {|p|
      @address_components << AddressComponent.new(p)
    }
  end

  def self.mongo_client
    @@db ||= Mongoid::Clients.default
  end

  def self.collection
    self.mongo_client['places']
  end

  def self.load_all(file_path)
    file=File.read(file_path)
    hash=JSON.parse(file)
    self.collection.insert_many(hash)
  end

  def self.find_by_short_name short_name
    self.collection.find('address_components.short_name'=>short_name)
  end

  def self.to_places docs
    places=[]
    docs.map do |doc|
      places << Place.new(doc)
    end
    return places
  end

  def self.find id
    result = collection.find({:_id=>BSON::ObjectId.from_string(id)}).first
    return result.nil? ? nil : Place.new(result)
  end

  def self.all(offset=0, limit=0)
    to_places self.collection.find().skip(offset).limit(limit)
  end

  def destroy
    self.class.collection.find(:_id=>BSON::ObjectId.from_string(@id)).delete_one
  end

end
