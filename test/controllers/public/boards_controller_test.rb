require "test_helper"

class Public::BoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin

    boards(:writebook).publish
  end

  test "show" do
    get published_board_path(boards(:writebook))
    assert_response :success
  end

  test "show can be framed by the personal site" do
    get published_board_path(boards(:writebook))

    assert_nil response.headers["X-Frame-Options"]
    assert_match %r{frame-ancestors 'self' https://vmattoo.dev}, response.headers["Content-Security-Policy"]
  end

  test "authenticated pages still refuse to be framed" do
    get board_path(boards(:writebook))

    assert_equal "SAMEORIGIN", response.headers["X-Frame-Options"]
    assert_match %r{frame-ancestors 'self'(;|$)}, response.headers["Content-Security-Policy"]
  end

  test "not found if the board is not published" do
    key = boards(:writebook).publication.key

    boards(:writebook).unpublish
    get public_board_path(key)

    assert_response :not_found
  end

  test "show excludes draft cards from closed count" do
    draft_card = cards(:buy_domain)
    draft_card.update!(status: :drafted)
    Current.set(user: users(:david)) { draft_card.close }

    get published_board_path(boards(:writebook))
    assert_response :success
    assert_select ".cards--closed .cards__expander-count", "1"
  end

  test "show works without authentication" do
    sign_out
    get published_board_path(boards(:writebook))
    assert_response :success
  end
end
