class Photo

  attr_accessor :id, :location, :contents

  def initialize params
    @id = params[:_id]
    @location = params[:metadata][:location]
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

end