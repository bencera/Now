# -*- encoding : utf-8 -*-
require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "question_answered" do
    mail = UserMailer.question_answered
    assert_equal "Question answered", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
