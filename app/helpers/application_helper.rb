module ApplicationHelper
  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = "Dictionary"
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end
  def map_lang_code_to_text(code)
	return @languages[code] if @languages.has_key?(code)
	return code
  end
end
