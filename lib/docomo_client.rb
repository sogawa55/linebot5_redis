require 'docomoru'
 
class DocomoClient
  def initialize(api_key = nil)
    @api_key = api_key
  end
 
  def chat(message, mode="dialog",context=nil)
    client = Docomoru::Client.new(api_key: ENV["DOCOMO_API_KEY"])
    response = client.create_dialogue(message,mode)
 
    return response
  end
end