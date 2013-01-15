require 'test_helper'

class NowCitiesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
