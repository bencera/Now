class FsPhotoUploader
  require 'net/http/post/multipart' # multipart-post gem
  require 'mime/types' #mime-types gem
  require 'net/https'
  require 'open-uri'


  def upload(file_path, access_token, options={})
    #we have to get the file into a tmp directory locally
    

    file_name = file_path.split("/").last
    output_path = "/tmp/#{file_name}"

    Net::HTTP.start("s3.amazonaws.com") do |http|
      resp = http.get(file_path)
      open("#{output_path}", "wb") do |file|
        file.write(resp.body)
      end
    end

    photo = File.open(output_path)
    
    params = {:oauth_token => access_token}
    params.merge!(options)
    url = URI.parse("https://api.foursquare.com/v2/photos/add")

    req = Net::HTTP::Post::Multipart.new "#{url.path}?#{params.to_query}",
        "file" => UploadIO.new(photo, mime_for_file(photo), photo.path)

    n = Net::HTTP.new(url.host, url.port)
    n.use_ssl = true
    n.verify_mode = OpenSSL::SSL::VERIFY_NONE

    response = nil

    retry_attempts = 5

    while response.nil? || retry_attempts > 0
      response = n.start do |http|
        http.request(req)
      end

      if response.code == "200"
        retry_attempts = 0
      else
        retry_attempts -= 1
        sleep 0.25
      end
    end
  end

private
  def mime_for_file(f)
    m = MIME::Types.type_for(f.path.split('').last)
    m.empty? ? "application/octet-stream" : m.to_s
  end
end
