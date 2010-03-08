module Layouts::CollegiateHelper
# format tinyMCE edit window titlebar for basic layout
  def set_tiny_options_collegiate(session)   
      @tiny_mce_options["width"] = "100%"
      @tiny_mce_options["height"] = "560"
      @tiny_mce_options["theme_advanced_buttons1"] = %w{bold italic underline separator strikethrough justifyleft justifycenter justifyright justifyfull separator formatselect bullist numlist table undo redo link unlink code}
      @tiny_mce_options["theme_advanced_buttons2"] = []
      @tiny_mce_options["theme_advanced_buttons3"] = []
  end
end