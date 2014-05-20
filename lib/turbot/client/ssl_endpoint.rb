class Turbot::Client
  def ssl_endpoint_add(bot, pem, key)
    json_decode(post("bots/#{bot}/ssl-endpoints", :accept => :json, :pem => pem, :key => key).to_s)
  end

  def ssl_endpoint_info(bot, cname)
    json_decode(get("bots/#{bot}/ssl-endpoints/#{escape(cname)}", :accept => :json).to_s)
  end

  def ssl_endpoint_list(bot)
    json_decode(get("bots/#{bot}/ssl-endpoints", :accept => :json).to_s)
  end

  def ssl_endpoint_remove(bot, cname)
    json_decode(delete("bots/#{bot}/ssl-endpoints/#{escape(cname)}", :accept => :json).to_s)
  end

  def ssl_endpoint_rollback(bot, cname)
    json_decode(post("bots/#{bot}/ssl-endpoints/#{escape(cname)}/rollback", :accept => :json).to_s)
  end

  def ssl_endpoint_update(bot, cname, pem, key)
    json_decode(put("bots/#{bot}/ssl-endpoints/#{escape(cname)}", :accept => :json, :pem => pem, :key => key).to_s)
  end
end
