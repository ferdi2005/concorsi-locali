# config/initializers/groupdate.rb
require "delegate"

Groupdate.week_start = :mon

# Su MariaDB ToolsDB (Wikimedia Toolforge), le tabelle dei fusi orari nominati (es. 'Europe/Rome')
# non sono caricate nel database di sistema mysql e CONVERT_TZ('Europe/Rome') restituisce NULL.
# MariaDB supporta però nativamente la conversione con offset numerico (es. '+01:00' o '+02:00').
# Usiamo lo stesso fuso a offset fisso sia per la query SQL (RelationBuilder) sia per la
# conversione e validazione della serie in Ruby (Magic::Relation e SeriesBuilder).
if ENV["TOOLFORGE"] == "true"
  module GroupdateMysqlTimezonePatch
    class FixedOffsetTzInfo < SimpleDelegator
      def initialize(tzinfo, sql_offset_name)
        super(tzinfo)
        @sql_offset_name = sql_offset_name
      end

      def name
        @sql_offset_name
      end
    end

    def time_zone
      @fixed_time_zone ||= begin
        base_tz = super
        return base_tz unless base_tz

        offset_seconds = Time.current.in_time_zone(base_tz).utc_offset
        offset_name = Time.current.in_time_zone(base_tz).strftime("%:z")
        hours = offset_seconds / 3600
        etc_name = hours >= 0 ? "Etc/GMT-#{hours}" : "Etc/GMT+#{-hours}"
        tzinfo = FixedOffsetTzInfo.new(TZInfo::Timezone.get(etc_name), offset_name)
        ActiveSupport::TimeZone.create(offset_name, offset_seconds, tzinfo)
      end
    end
  end

  Groupdate::Magic.prepend(GroupdateMysqlTimezonePatch)
end