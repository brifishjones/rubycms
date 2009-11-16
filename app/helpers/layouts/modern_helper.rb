module Layouts::ModernHelper
# format tinyMCE edit window titlebar for modern layout
  def set_tiny_options_modern(session)   
    if session[:layout]  == "modern/section"
      @tiny_mce_options["width"] = "100%"
      @tiny_mce_options["height"] = "420"
      @tiny_mce_options["theme_advanced_buttons1"] = %w{bold italic underline separator strikethrough justifyleft justifycenter justifyright justifyfull}
      @tiny_mce_options["theme_advanced_buttons2"] = %w{bullist numlist table undo redo link unlink code formatselect}
      @tiny_mce_options["theme_advanced_buttons3"] = []
    else
      @tiny_mce_options["width"] = "100%"
      @tiny_mce_options["height"] = "560"
      @tiny_mce_options["theme_advanced_buttons1"] = %w{bold italic underline separator strikethrough justifyleft justifycenter justifyright justifyfull separator formatselect bullist numlist table undo redo link unlink code}
      @tiny_mce_options["theme_advanced_buttons2"] = []
      @tiny_mce_options["theme_advanced_buttons3"] = []
    end
  end
end