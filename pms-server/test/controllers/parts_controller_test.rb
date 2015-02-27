require 'test_helper'

class PartsControllerTest < ActionController::TestCase
  setup do
    @part = parts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:parts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create part" do
    assert_difference('Part.count') do
      post :create, part: { custom_nr: @part.custom_nr, measure_unit_id: @part.measure_unit_id, nr: @part.nr, resource_group_id: @part.resource_group_id, strip_length: @part.strip_length, type: @part.type }
    end

    assert_redirected_to part_path(assigns(:part))
  end

  test "should show part" do
    get :show, id: @part
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @part
    assert_response :success
  end

  test "should update part" do
    patch :update, id: @part, part: { custom_nr: @part.custom_nr, measure_unit_id: @part.measure_unit_id, nr: @part.nr, resource_group_id: @part.resource_group_id, strip_length: @part.strip_length, type: @part.type }
    assert_redirected_to part_path(assigns(:part))
  end

  test "should destroy part" do
    assert_difference('Part.count', -1) do
      delete :destroy, id: @part
    end

    assert_redirected_to parts_path
  end
end
