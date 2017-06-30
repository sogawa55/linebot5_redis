class WebhookController < ApplicationController
  # Lineからのcallbackか認証
  protect_from_forgery with: :null_session

  CHANNEL_SECRET = ENV['CHANNEL_SECRET']
  OUTBOUND_PROXY = ENV['OUTBOUND_PROXY']
  CHANNEL_ACCESS_TOKEN = ENV['CHANNEL_ACCESS_TOKEN']

  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end
    
    params = JSON.parse(request.body.read)
    
    event = params["events"][0]
    replyToken = event["replyToken"]
    user_text = event["text"].to_s
  
     docomo_client = DocomoClient.new(api_key: ENV["DOCOMO_API_KEY"])
    
    from = response.body['context']
    mode = response.body['mode']
    context = $redis.set('user_id', from)
    lastmode = $redis.set('mode', mode)
    response =  docomo_client.chat(user_text, lastmode, context)
    context = $redis.set('user_id', response.body['context'])
    lastmode = $redis.set('mode', response.body['mode'])
    
   
    message = response.body['utt']
     
    output_text = message

    client = LineClient.new(CHANNEL_ACCESS_TOKEN, OUTBOUND_PROXY)
    res = client.reply(replyToken, output_text)

    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end

    render :nothing => true, status: :ok
  end


  private
  # verify access from LINE
  def is_validate_signature
    signature = request.headers["X-LINE-Signature"]
    http_request_body = request.raw_post
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, CHANNEL_SECRET, http_request_body)
    signature_answer = Base64.strict_encode64(hash)
    signature == signature_answer
  end
end