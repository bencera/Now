silence_warnings do
  Delayed::Job.const_set("MAX_ATTEMPTS", 1)
  Delayed::Job.const_set("MAX_RUN_TIME", 10.minutes)
end