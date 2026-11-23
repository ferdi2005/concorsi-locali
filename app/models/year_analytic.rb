class YearAnalytic < ApplicationRecord
  belongs_to :year

  def reuse_by_monument_bucket
    return {} if reuse_by_monument_bucket_json.blank?

    JSON.parse(reuse_by_monument_bucket_json)
  rescue JSON::ParserError
    {}
  end

  def reuse_by_monument_bucket=(hash)
    self.reuse_by_monument_bucket_json = hash.to_json
  end

  def top_monuments
    return [] if top_monuments_json.blank?

    JSON.parse(top_monuments_json)
  rescue JSON::ParserError
    []
  end

  def top_monuments=(list)
    self.top_monuments_json = list.to_json
  end
end
