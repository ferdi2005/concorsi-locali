module Toolforge
  class UpdateExifWorker
    include Sidekiq::Worker
    sidekiq_options({
      unique: :all
    })

    SMARTPHONE_MAKES = %w[
      apple samsung xiaomi huawei oppo vivo realme oneplus motorola nokia
      google pixel redmi poco honor nothing fairphone asus_phone lg htc
      meizu lenovo tecno infinix wiko alcatel
    ].freeze

    SMARTPHONE_MODEL_REGEX = /(iphone|galaxy|sm-[a-z]\d|pixel|redmi|mi\s?\d|poco|moto\s|oneplus|huawei|honor|oppo|realme|vivo|xperia|ipad|cph\d|rmx\d|22\d{5}[a-z])/i.freeze
    CAMERA_MAKE_REGEX = /(canon|nikon|sony|fujifilm|fuji|olympus|panasonic|leica|pentax|ricoh|hasselblad|casio|kodak|minolta|konica|sigma|dji|gopro|lumix|om\s?digital)/i.freeze

    def perform(year_id = nil, max_photos = 20_000)
      scope = Photo.where(exif_checked_at: nil)
      scope = scope.where(year_id: year_id) if year_id.present?

      processed = 0
      scope.in_batches(of: 500) do |batch|
        break if max_photos && processed >= max_photos

        process_batch(batch)
        processed += batch.size
      end
    end

    def self.extract_exif_fields(raw_metadata)
      return { has_exif: false, device_category: "unknown" } if raw_metadata.blank?

      make = nil
      model = nil
      raw_date = nil

      stripped = raw_metadata.strip
      if stripped.start_with?("{")
        parsed = JSON.parse(stripped) rescue nil
        if parsed.is_a?(Hash)
          data = parsed["data"].is_a?(Hash) ? parsed["data"] : parsed
          make = data["Make"] || data["make"]
          model = data["Model"] || data["model"]
          raw_date = data["DateTimeOriginal"] || data["DateTimeDigitized"] || data["DateTime"]
        end
      else
        # Parsing leggero per blob PHP serializzato MediaWiki (es. s:4:"Make";s:5:"Apple";)
        make = extract_php_serialized_string(raw_metadata, "Make")
        model = extract_php_serialized_string(raw_metadata, "Model")
        raw_date = extract_php_serialized_string(raw_metadata, "DateTimeOriginal") ||
                   extract_php_serialized_string(raw_metadata, "DateTimeDigitized") ||
                   extract_php_serialized_string(raw_metadata, "DateTime")
      end

      make = clean_exif_value(make)
      model = clean_exif_value(model)
      taken_at = parse_exif_datetime(raw_date)
      has_exif = make.present? || model.present? || taken_at.present?

      {
        taken_at: taken_at,
        camera_make: make,
        camera_model: model,
        device_category: classify_device(make, model),
        has_exif: has_exif
      }
    end

    def self.extract_php_serialized_string(blob, key)
      pattern = /s:#{key.length}:"#{Regexp.escape(key)}";s:\d+:"([^"]*)"/
      match = blob.match(pattern)
      match ? match[1] : nil
    end

    def self.clean_exif_value(val)
      return nil if val.nil?

      s = val.to_s.gsub("\u0000", "").strip
      s.empty? ? nil : s.first(250)
    end

    def self.parse_exif_datetime(raw)
      return nil if raw.blank?

      s = raw.to_s.strip
      if (m = s.match(/\A(\d{4}):(\d{2}):(\d{2})(?:[ T](\d{2}):(\d{2}):(\d{2}))?/))
        Time.utc(m[1].to_i, m[2].to_i, m[3].to_i, m[4].to_i, m[5].to_i, m[6].to_i)
      else
        Time.parse(s).utc
      end
    rescue ArgumentError
      nil
    end

    def self.classify_device(make, model)
      return "unknown" if make.blank? && model.blank?

      combined = "#{make} #{model}".downcase
      return "smartphone" if SMARTPHONE_MODEL_REGEX.match?(combined)
      return "smartphone" if SMARTPHONE_MAKES.any? { |brand| make.to_s.downcase.include?(brand) }
      return "camera" if CAMERA_MAKE_REGEX.match?(combined)

      "camera"
    end

    private

    def process_batch(batch)
      rows = batch.pluck(:id, :pageid)
      pageids = rows.filter_map { |_, pid| pid }.uniq
      return if pageids.empty?

      metadata_by_pageid = WikimediaReplicaClient.fetch_file_metadata_for_pageids(pageids)
      now = Time.current

      rows.each do |photo_id, pageid|
        next if pageid.nil?

        fields = self.class.extract_exif_fields(metadata_by_pageid[pageid.to_i])
        Photo.where(id: photo_id).update_all(
          taken_at: fields[:taken_at],
          camera_make: fields[:camera_make],
          camera_model: fields[:camera_model],
          device_category: fields[:device_category],
          has_exif: fields[:has_exif],
          exif_checked_at: now,
          updated_at: now
        )
      end
    end
  end
end
