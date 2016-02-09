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

  def self.get_address_components(sort={:_id=>1},offset=0,limit=99999)
    self.collection.find().aggregate([
      {:$project=>{:_id=>1, :address_components=>1,:formatted_address=>1,'geometry.geolocation'=>1}},
      {:$unwind=>'$address_components'},
      {:$sort=>sort},
      {:$skip=>offset},
      {:$limit=>limit}
    ])
    #queries = [{:$project=> ...}]
    #queries.append({:$limit=>...}] if !limit.nil?
    #collection.aggregate(queries)
  end

  def self.get_country_names
    country_names = []
    self.collection.find().aggregate([
      {:$project=>{ 'address_components.long_name'=>1, 'address_components.types'=>1}},
      {:$unwind => '$address_components'},
      {:$match=>{'address_components.types'=>'country'}},
      {:$group=>{ :_id=>'$address_components.long_name'}}
    ]).to_a.map {|doc| country_names << doc[:_id]}
    return country_names
  end

  def self.find_ids_by_country_code country_code
    country_ids = []
    self.collection.find().aggregate([
       {:$unwind => '$address_components'},
       {:$match=>{'address_components.types'=>'country','address_components.short_name'=>country_code}}
    ]).to_a.map {|doc| country_ids << doc[:_id].to_s}
    return country_ids
  end

  def self.create_indexes
    self.collection.indexes.create_one({ "geometry.geolocation" => Mongo::Index::GEO2DSPHERE })
  end

  def self.remove_indexes
    self.collection.indexes.drop_one("geometry.geolocation_2dsphere")
  end

  def self.near(point,max_meters=0)
    self.collection.find( { "geometry.geolocation" =>
        { $near =>
          { $geometry =>
            { :type => "Point" ,
              :coordinates => point.to_hash[:coordinates] }
          }
        } } )
  end

end
