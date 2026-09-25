def ref
  begin
  require_relative "../lib"
  require_relative "../../../lib/rb_art"
  rescue
    return false
  end
  true
end