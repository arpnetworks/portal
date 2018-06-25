@config = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', '..', 'config', 'arp', 'redis.yml')))

if redis_conf = @config[Rails.env]
  @REDIS_URL = "redis://" +
               redis_conf['host'] + ":" +
               redis_conf['port'].to_s + "/" +
               redis_conf['db'].to_s

  ARP_REDIS = Redis.new(:url => @REDIS_URL,
                        :network_timeout => redis_conf['timeout'],
                        :password => redis_conf['password'].empty? ? nil : redis_conf['password'])
end

def build_and_reload_conserver(host)
  ARP_REDIS.lpush("queue:#{host}",
                  "{ \"class\": \"ConserverCfBuilderWorker\", \"args\": null, \"jid\": \"#{SecureRandom.hex(12)}\", \"retry\": true, \"enqueued_at\": #{Time.now.to_f.to_s}, \"created_at\": #{Time.now.to_f.to_s} }");
end
