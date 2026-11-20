require "set"

# Client in sola lettura per interrogare le database replica di Wikimedia Toolforge
# (commonswiki_p su cluster s4 e links x4, e centralauth_p su s7) senza effettuare
# richieste HTTP alle API MediaWiki.
class WikimediaReplicaClient
  KNOWN_IDS_CATEGORY = "Cultural_heritage_monuments_in_Italy_with_known_IDs".freeze
  DEFAULT_WLM_TEMPLATE = "Monumento_italiano".freeze
  BATCH_SIZE = 1000

  class << self
    def enabled?
      ENV["TOOLFORGE"] == "true" || ENV["USE_TOOLFORGE_REPLICAS"] == "true"
    end

    def normalize_category_title(title)
      title.to_s.strip.sub(/\ACategory:/i, "").tr(" ", "_")
    end

    def normalize_file_title(title)
      title.to_s.strip.sub(/\AFile:/i, "").tr(" ", "_")
    end

    def denormalize_file_title(db_title)
      "File:#{decode(db_title).to_s.tr('_', ' ')}"
    end

    def decode(val)
      return nil if val.nil?

      val.to_s.dup.force_encoding(Encoding::UTF_8).scrub
    end

    def parse_mediawiki_timestamp(raw_ts)
      s = decode(raw_ts)&.strip
      return nil if s.nil? || s.empty? || !s.match?(/\A\d{14}\z/)

      Time.utc(
        s[0, 4].to_i,
        s[4, 2].to_i,
        s[6, 2].to_i,
        s[8, 2].to_i,
        s[10, 2].to_i,
        s[12, 2].to_i
      )
    rescue ArgumentError
      nil
    end

    def reset_schema_cache!
      @uses_file_revision_tables = nil
      @categorylinks_uses_linktarget = nil
    end

    def uses_file_revision_tables?
      return @uses_file_revision_tables unless @uses_file_revision_tables.nil?

      @uses_file_revision_tables =
        commons_connection.data_source_exists?("filerevision") &&
        commons_connection.data_source_exists?("file")
    end

    def categorylinks_uses_linktarget?
      return @categorylinks_uses_linktarget unless @categorylinks_uses_linktarget.nil?

      @categorylinks_uses_linktarget =
        commons_links_connection.column_exists?("categorylinks", "cl_target_id")
    end

    def fetch_category_files_counts(category_titles)
      normalized = category_titles.filter_map do |title|
        norm = normalize_category_title(title)
        norm unless norm.empty?
      end.uniq
      return {} if normalized.empty?

      conn = commons_connection
      counts = {}

      normalized.each_slice(BATCH_SIZE) do |slice|
        quoted = slice.map { |t| conn.quote(t) }.join(", ")
        sql = <<~SQL
          SELECT cat_title, cat_files
          FROM category
          WHERE cat_title IN (#{quoted})
        SQL

        conn.select_all(sql).each do |row|
          counts[decode(row["cat_title"])] = row["cat_files"].to_i
        end
      end

      counts
    end

    def fetch_category_photos(category_title)
      norm_cat = normalize_category_title(category_title)
      return [] if norm_cat.empty?

      links_conn = commons_links_connection
      cat_join, cat_where = category_filter_sql(links_conn, "cl", norm_cat)

      pageids_sql = <<~SQL
        SELECT p.page_id AS pageid
        FROM categorylinks cl
        #{cat_join}
        JOIN page p
          ON p.page_id = cl.cl_from
         AND p.page_namespace = 6
        #{cat_where.empty? ? "" : "WHERE #{cat_where}"}
      SQL

      pageids = links_conn.select_all(pageids_sql).map { |row| row["pageid"].to_i }.uniq
      return [] if pageids.empty?

      core_conn = commons_connection
      if uses_file_revision_tables?
        timestamp_expr = "fr.fr_timestamp"
        file_actor_join = <<~SQL
          JOIN file f
            ON f.file_name = p.page_title
          JOIN filerevision fr
            ON fr.fr_id = f.file_latest
          JOIN actor a
            ON a.actor_id = fr.fr_actor
        SQL
      else
        timestamp_expr = "i.img_timestamp"
        file_actor_join = <<~SQL
          JOIN image i
            ON i.img_name = p.page_title
          JOIN actor a
            ON a.actor_id = i.img_actor
        SQL
      end

      photos = []
      pageids.each_slice(BATCH_SIZE) do |slice|
        sql = <<~SQL
          SELECT
            p.page_id AS pageid,
            p.page_title AS page_title,
            #{timestamp_expr} AS img_timestamp,
            a.actor_name AS username,
            a.actor_user AS userid
          FROM page p
          #{file_actor_join}
          WHERE p.page_id IN (#{slice.join(', ')})
            AND p.page_namespace = 6
        SQL

        core_conn.select_all(sql).each do |row|
          photos << {
            "pageid" => row["pageid"].to_i,
            "title" => denormalize_file_title(row["page_title"]),
            "user" => decode(row["username"]),
            "userid" => row["userid"]&.to_i,
            "timestamp" => parse_mediawiki_timestamp(row["img_timestamp"])
          }
        end
      end

      photos
    end

    def fetch_category_member_titles(category_title, namespace: 6)
      norm_cat = normalize_category_title(category_title)
      return Set.new if norm_cat.empty?

      conn = commons_links_connection
      cat_join, cat_where = category_filter_sql(conn, "cl", norm_cat)
      ns = namespace.to_i

      sql = <<~SQL
        SELECT p.page_title AS page_title
        FROM categorylinks cl
        #{cat_join}
        JOIN page p
          ON p.page_id = cl.cl_from
         AND p.page_namespace = #{ns}
        #{cat_where.empty? ? "" : "WHERE #{cat_where}"}
      SQL

      titles = Set.new
      conn.select_all(sql).each do |row|
        raw_title = row["page_title"]
        titles.add(ns == 6 ? denormalize_file_title(raw_title) : decode(raw_title).tr("_", " "))
      end
      titles
    end

    def fetch_wlmids_for_pageids(pageids)
      ids = normalize_pageids(pageids)
      return {} if ids.empty?

      conn = commons_links_connection
      cat_join, cat_where = category_filter_sql(conn, "cl", KNOWN_IDS_CATEGORY)
      wlmids = {}

      ids.each_slice(BATCH_SIZE) do |slice|
        conditions = ["cl.cl_from IN (#{slice.join(', ')})"]
        conditions << cat_where unless cat_where.empty?

        sql = <<~SQL
          SELECT
            cl.cl_from AS pageid,
            cl.cl_sortkey_prefix AS sortkey_prefix
          FROM categorylinks cl
          #{cat_join}
          WHERE #{conditions.join(' AND ')}
        SQL

        conn.select_all(sql).each do |row|
          wlmid = decode(row["sortkey_prefix"])&.strip
          wlmids[row["pageid"].to_i] = wlmid unless wlmid.nil? || wlmid.empty?
        end
      end

      wlmids
    end

    def fetch_user_registrations(usernames)
      names = usernames.filter_map do |username|
        str = username.to_s
        str unless str.strip.empty?
      end.uniq
      return {} if names.empty?

      registrations = {}
      ca_conn = centralauth_connection

      names.each_slice(BATCH_SIZE) do |slice|
        quoted = slice.map { |u| ca_conn.quote(u) }.join(", ")
        sql = <<~SQL
          SELECT gu_name, gu_registration
          FROM globaluser
          WHERE gu_name IN (#{quoted})
        SQL

        ca_conn.select_all(sql).each do |row|
          name = decode(row["gu_name"])
          ts = parse_mediawiki_timestamp(row["gu_registration"])
          registrations[name] = ts unless ts.nil?
        end
      end

      missing = names.reject { |name| registrations.key?(name) }
      if missing.any?
        c_conn = commons_connection
        missing.each_slice(BATCH_SIZE) do |slice|
          quoted = slice.map { |u| c_conn.quote(u) }.join(", ")
          sql = <<~SQL
            SELECT user_name, user_registration
            FROM user
            WHERE user_name IN (#{quoted})
          SQL

          c_conn.select_all(sql).each do |row|
            name = decode(row["user_name"])
            ts = parse_mediawiki_timestamp(row["user_registration"])
            registrations[name] = ts unless ts.nil?
          end
        end
      end

      registrations
    end

    def fetch_globally_used_pageids(pageids)
      ids = normalize_pageids(pageids)
      return {} if ids.empty?

      conn = commons_links_connection
      used = {}

      ids.each_slice(BATCH_SIZE) do |slice|
        sql = <<~SQL
          SELECT DISTINCT p.page_id AS pageid
          FROM page p
          JOIN globalimagelinks gil ON gil.gil_to = p.page_title
          WHERE p.page_id IN (#{slice.join(', ')})
            AND gil.gil_page_namespace_id = 0
        SQL

        conn.select_all(sql).each do |row|
          used[row["pageid"].to_s] = true
        end
      end

      used
    end

    def fetch_pageids_with_template(pageids, template_title = DEFAULT_WLM_TEMPLATE)
      ids = normalize_pageids(pageids)
      return Set.new if ids.empty?

      norm_tpl = template_title.to_s.strip.sub(/\ATemplate:/i, "").tr(" ", "_")
      conn = commons_links_connection
      quoted_tpl = conn.quote(norm_tpl)
      valid = Set.new

      ids.each_slice(BATCH_SIZE) do |slice|
        sql = <<~SQL
          SELECT DISTINCT tl.tl_from AS pageid
          FROM templatelinks tl
          JOIN linktarget lt ON tl.tl_target_id = lt.lt_id
          WHERE lt.lt_namespace = 10
            AND lt.lt_title = #{quoted_tpl}
            AND tl.tl_from IN (#{slice.join(', ')})
        SQL

        conn.select_all(sql).each do |row|
          valid.add(row["pageid"].to_i)
        end
      end

      valid
    end

    private

    def commons_connection
      CommonsReplicaRecord.connection
    end

    def commons_links_connection
      CommonsLinksReplicaRecord.connection
    end

    def centralauth_connection
      CentralAuthReplicaRecord.connection
    end

    def normalize_pageids(pageids)
      pageids.filter_map { |id| id.to_i if id.present? && id.to_i.positive? }.uniq
    end

    def category_filter_sql(conn, table_alias, normalized_category_title)
      quoted_cat = conn.quote(normalized_category_title)

      if categorylinks_uses_linktarget?
        join_sql = <<~SQL
          JOIN linktarget lt_#{table_alias}
            ON #{table_alias}.cl_target_id = lt_#{table_alias}.lt_id
           AND lt_#{table_alias}.lt_namespace = 14
           AND lt_#{table_alias}.lt_title = #{quoted_cat}
        SQL
        [join_sql, ""]
      else
        ["", "#{table_alias}.cl_to = #{quoted_cat}"]
      end
    end
  end
end
