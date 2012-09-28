class RetryPhotos
  @queue = :retry_photos_queue

  def self.perform
    # get string of ig_ids and retry instagram pull.  if it fails, add the ids back to the rdis 
  end
end