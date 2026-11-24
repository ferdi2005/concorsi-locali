module ApplicationHelper
  WLM_CHART_COLORS = %w[#2563eb #dc2626 #16a34a #d97706 #7c3aed #475569].freeze

  def wlm_chart_colors
    WLM_CHART_COLORS
  end

  def fmt_int(value)
    return "-" if value.nil?

    number_with_delimiter(value.to_i, delimiter: ".")
  end

  def fmt_dec(value, precision: 1)
    return "-" if value.nil?

    number_with_precision(value.to_f, precision: precision, separator: ",", delimiter: ".")
  end

  def fmt_pct(value, precision: 1)
    return "-" if value.nil?

    "#{fmt_dec(value, precision: precision)}%"
  end

  def delta_badge(current, previous, previous_label:, invert: false)
    return "".html_safe if current.nil? || previous.nil? || previous.to_f <= 0

    diff_pct = ((current.to_f - previous.to_f) / previous.to_f * 100.0).round(1)
    sign = diff_pct > 0 ? "+" : ""
    positive_is_good = !invert
    css = if diff_pct == 0
            "is-light"
          elsif (diff_pct > 0 && positive_is_good) || (diff_pct < 0 && !positive_is_good)
            "is-success is-light"
          else
            "is-danger is-light"
          end

    content_tag(:span, "#{sign}#{fmt_dec(diff_pct)}% rispetto al #{previous_label}", class: "tag #{css} mt-1")
  end

  def nav_active_class(path)
    current_page?(path) ? "is-active has-background-link-light has-text-weight-semibold" : ""
  end
end
