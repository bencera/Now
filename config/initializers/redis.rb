uri = URI.parse('redis://redistogo:ea140da2aecd9e0c20f410b1be6bfdb1@viperfish.redistogo.com:9774/')
$redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)