const fs = require('fs');

const USERNAME = 'nrupala';
const TOKEN = process.env.GH_TOKEN;

async function generatePortfolio() {
  console.log(`Fetching repositories for ${USERNAME}...`);
  
  const headers = {
    'Accept': 'application/vnd.github.v3+json',
    'User-Agent': 'Portfolio-Build-Script'
  };

  if (TOKEN) {
    headers['Authorization'] = `token ${TOKEN}`;
  }

  try {
    const res = await fetch(`https://api.github.com/users/${USERNAME}/repos?sort=updated&per_page=100`, { headers });

    if (!res.ok) {
      throw new Error(`GitHub API error: ${res.status} ${res.statusText}`);
    }
    
    const repos = await res.json();
    const publicRepos = repos.filter(r => !r.fork);

    console.log(`Found ${publicRepos.length} public non-fork repositories.`);

    // Generate static cards HTML
    const cardsHtml = publicRepos.map(repo => {
      const lang = repo.language || 'Unspecified';
      const name = repo.name;
      const desc = repo.description || 'No description provided.';
      const updatedDate = new Date(repo.updated_at).toLocaleDateString('en-US', { month: 'short', year: 'numeric' });

      return `
        <div class="repo-card" data-name="${name.toLowerCase()}" data-desc="${desc.toLowerCase()}" data-lang="${lang}">
          <div>
            <div class="repo-header">
              <a class="repo-title" href="${repo.html_url}" target="_blank" rel="noopener">${name}</a>
              <a class="source-link" href="${repo.html_url}" target="_blank" rel="noopener">GitHub ↗</a>
            </div>
            <div class="repo-desc">${desc}</div>
          </div>
          <div>
            <div class="stats-panel">
              <div><div class="stat-val">⭐ ${repo.stargazers_count}</div><div class="stat-lbl">Stars</div></div>
              <div><div class="stat-val">🍴 ${repo.forks_count}</div><div class="stat-lbl">Forks</div></div>
              <div><div class="stat-val">📦 ${(repo.size / 1024).toFixed(1)}M</div><div class="stat-lbl">Size</div></div>
            </div>
            <div class="meta-footer">
              <span class="lang-badge">${lang}</span>
              <span class="date-lbl">Updated ${updatedDate}</span>
            </div>
          </div>
        </div>`;
    }).join('\n');

    // Extract unique languages for the filter dropdown
    const languages = [...new Set(publicRepos.map(r => r.language).filter(Boolean))];
    const optionsHtml = ['<option value="all">All Languages</option>', ...languages.map(l => `<option value="${l}">${l}</option>`)].join('\n');

    // Read template.html and inject compiled HTML
    let template = fs.readFileSync('template.html', 'utf8');
    template = template.replace('<!-- REPO_CARDS -->', cardsHtml);
    template = template.replace('<!-- LANG_OPTIONS -->', optionsHtml);

    fs.writeFileSync('index.html', template);
    console.log('Successfully written compiled HTML to index.html');

  } catch (err) {
    console.error('Build failed:', err);
    process.exit(1);
  }
}

generatePortfolio();
