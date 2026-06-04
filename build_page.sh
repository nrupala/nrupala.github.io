#!/bin/bash

# Parse JSON layout configurations using standard JQ parameters
CARDS_HTML=""
LANG_OPTIONS="<option value=\"all\">All Languages</option>"
UNIQUE_LANGS=$(jq -r '.[] | select(.has_pages == true and (.name | ascii_lowercase) != "nrupala.github.io") | .language' repos.json | sort -u | grep -v "null")

for lang in $UNIQUE_LANGS; do
  LANG_OPTIONS="$LANG_OPTIONS<option value=\"${lang,,}\">$lang</option>"
done

# Read through repositories array
while read -r repo; do
  [ -z "$repo" ] && continue
  
  NAME=$(echo "$repo" | jq -r '.name')
  DESC=$(echo "$repo" | jq -r '.description // "Production build active."')
  LANG=$(echo "$repo" | jq -r '.language // "Config"')
  STARS=$(echo "$repo" | jq -r '.stargazers_count // 0')
  FORKS=$(echo "$repo" | jq -r '.forks_count // 0')
  SIZE=$(echo "$repo" | jq -r '.size // 0')
  URL=$(echo "$repo" | jq -r '.homepage // empty')
  SRC=$(echo "$repo" | jq -r '.html_url')
  DATE=$(date -d "$(echo "$repo" | jq -r '.updated_at')" +"%b %Y" 2>/dev/null || echo "Recent")

  if [ -z "$URL" ]; then
    URL="https://github.io"
  fi

  # Calculate Engagement Metrics
  SCORE=$(( (STARS * 3) + (FORKS * 2) + (SIZE / 500) + 1 ))

  # Generate predictable visual telemetry vectors
  BASE=$(( (STARS * 4) + (FORKS * 6) ))
  [ $BASE -lt 8 ] && BASE=$(( (RANDOM % 12) + 8 ))
  POINTS=""
  for i in {0..6}; do
    X=$(( (i * 400) / 6 ))
    Y=$(( 42 - (BASE * 7 / 10) ))
    [ $Y -lt 5 ] && Y=5
    [ $Y -gt 40 ] && Y=40
    POINTS="$POINTS $X,$Y"
  done

  CARDS_HTML="$CARDS_HTML
  <div class=\"repo-card\" data-name=\"${NAME,,}\" data-desc=\"${DESC,,}\" data-lang=\"${LANG,,}\">
      <div class=\"repo-header\">
          <a href=\"$URL\" class=\"repo-title\" target=\"_blank\">🌐 $NAME</a>
          <a href=\"$SRC\" class=\"source-link\" target=\"_blank\">&lt;/&gt; Source</a>
      </div>
      <div class=\"repo-desc\">$DESC</div>
      <div class=\"graph-container\">
          <svg viewBox=\"0 0 400 45\" style=\"width:100%; height:100%; overflow:visible;\">
              <polyline fill=\"none\" stroke=\"#7ee787\" stroke-width=\"2\" points=\"$POINTS\" />
          </svg>
      </div>
      <div class=\"stats-panel\">
          <div><div class=\"stat-val\">★ $STARS</div><div class=\"stat-lbl\">Stars</div></div>
          <div><div class=\"stat-val\">⑂ $FORKS</div><div class=\"stat-lbl\">Forks</div></div>
          <div><div class=\"stat-val\">$SCORE</div><div class=\"stat-lbl\">Activity Index</div></div>
      </div>
      <div class=\"meta-footer\">
          <span class=\"lang-badge\">$LANG</span>
          <span class=\"date-lbl\">Pushed: $DATE</span>
      </div>
  </div>"
done < <(jq -c '.[] | select(.has_pages == true and (.name | ascii_lowercase) != "nrupala.github.io")' repos.json)

# Assemble flat structural template page code
cat <<EOF > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>nrupala | Engineering Portfolio</title>
    <style>
        :root { --bg-color: #0d1117; --card-bg: #161b22; --border-color: #30363d; --text-main: #c9d1d9; --text-muted: #8b949e; --accent-blue: #58a6ff; }
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 950px; margin: 0 auto; padding: 40px 20px; color: var(--text-main); background-color: var(--bg-color); line-height: 1.6; }
        h1 { font-size: 32px; font-weight: 700; color: #fff; margin-bottom: 5px; }
        .subtitle { color: var(--text-muted); margin-bottom: 30px; font-size: 16px; }
        .controls-panel { display: flex; gap: 15px; margin-bottom: 30px; flex-wrap: wrap; background: var(--card-bg); padding: 15px; border: 1px solid var(--border-color); border-radius: 8px; }
        .search-input { flex: 1; min-width: 200px; background: var(--bg-color); border: 1px solid var(--border-color); color: #fff; padding: 10px 15px; border-radius: 6px; font-size: 14px; }
        .filter-select { background: var(--bg-color); border: 1px solid var(--border-color); color: #fff; padding: 10px 15px; border-radius: 6px; cursor: pointer; }
        #repo-grid { display: grid; grid-template-columns: 1fr; gap: 20px; }
        @media(min-width: 768px) { #repo-grid { grid-template-columns: 1fr 1fr; } }
        .repo-card { background: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 20px; display: flex; flex-direction: column; justify-content: space-between; }
        .repo-card.hidden { display: none !important; }
        .repo-header { display: flex; justify-content: space-between; align-items: flex-start; }
        .repo-title { font-size: 18px; font-weight: 600; text-decoration: none; color: var(--accent-blue); }
        .source-link { font-size: 12px; color: var(--text-muted); text-decoration: none; }
        .repo-desc { margin: 12px 0; color: var(--text-muted); font-size: 14px; min-height: 42px; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
        .stats-panel { background: rgba(0, 0, 0, 0.2); border-radius: 6px; padding: 10px; margin: 12px 0; display: grid; grid-template-columns: repeat(3, 1fr); text-align: center; font-size: 12px; }
        .stat-val { font-size: 16px; font-weight: bold; color: #fff; }
        .stat-lbl { color: var(--text-muted); font-size: 11px; }
        .graph-container { height: 45px; margin: 10px 0; border-bottom: 1px dashed var(--border-color); }
        .meta-footer { display: flex; justify-content: space-between; align-items: center; margin-top: 10px; font-size: 12px; }
        .lang-badge { padding: 2px 8px; border-radius: 12px; background: rgba(88, 166, 255, 0.15); color: var(--accent-blue); font-weight: 600; }
        .date-lbl { color: var(--text-muted); }
    </style>
</head>
<body>
    <h1>nrupala // Engineering Dashboard</h1>
    <div class="subtitle">Compiled live portfolio metrics and directory of active web applications.</div>
    <div class="controls-panel">
        <input type="text" id="searchBar" class="search-input" placeholder="🔍 Search projects...">
        <select id="langFilter" class="filter-select">$LANG_OPTIONS</select>
    </div>
    <div id="repo-grid">$CARDS_HTML</div>
    <script>
        const searchBar = document.getElementById('searchBar');
        const langFilter = document.getElementById('langFilter');
        const cards = document.querySelectorAll('.repo-card');

        function filterData() {
            const query = searchBar.value.toLowerCase();
            const selectedLang = langFilter.value;
            cards.forEach(card => {
                const matchesSearch = card.getAttribute('data-name').includes(query) || card.getAttribute('data-desc').includes(query);
                const matchesLang = selectedLang === 'all' || card.getAttribute('data-lang') === selectedLang;
                card.classList.toggle('hidden', !(matchesSearch && matchesLang));
            });
        }
        searchBar.addEventListener('input', filterData);
        langFilter.addEventListener('change', filterData);
    </script>
</body>
</html>
EOF

# Clean up working metadata files cleanly
rm repos.json
