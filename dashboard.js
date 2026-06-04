const username = 'nrupala';
let allRepos = [];

async function initDashboard() {
    try {
        const response = await fetch(`https://github.com{username}/repos?per_page=100&sort=updated`);
        if (!response.ok) throw new Error('API Rate Limit Restriced');
        
        const repos = await response.json();
        // Filter out the hub architecture itself
        allRepos = repos.filter(repo => repo.has_pages && repo.name.toLowerCase() !== `${username}.github.io`.toLowerCase());
        
        if (allRepos.length === 0) {
            document.getElementById('repo-grid').innerHTML = '<div>No open-source tracking data flagged. Activate GitHub Pages in your other repositories.</div>';
            return;
        }

        populateFilters(allRepos);
        renderGrid(allRepos);
        
        document.getElementById('searchBar').addEventListener('input', applyFilters);
        document.getElementById('langFilter').addEventListener('change', applyFilters);
        
    } catch (err) {
        document.getElementById('repo-grid').innerHTML = '<div>API temporary downtime limit reached. Try re-evaluating shortly.</div>';
    }
}

function populateFilters(repos) {
    const languages = new Set();
    repos.forEach(r => { if(r.language) languages.add(r.language); });
    const select = document.getElementById('langFilter');
    languages.forEach(lang => {
        const opt = document.createElement('option');
        opt.value = lang.toLowerCase();
        opt.textContent = lang;
        select.appendChild(opt);
    });
}

function generatePopularityGraph(stars, forks) {
    const points = [];
    const steps = 6;
    let baseMetric = Math.max(8, (stars * 4) + (forks * 6));
    if (baseMetric === 8) baseMetric = Math.floor(Math.random() * 12) + 8; // Randomize slight movement for inactive repos

    for(let i = 0; i <= steps; i++) {
        const x = (i / steps) * 400;
        const variance = Math.sin(i * 1.5) * (baseMetric * 0.2);
        const y = Math.max(5, Math.min(40, 42 - (baseMetric * 0.7) - variance));
        points.push(`${x},${y}`);
    }
    return points.join(' ');
}

function renderGrid(repos) {
    const grid = document.getElementById('repo-grid');
    grid.innerHTML = '';

    repos.forEach(repo => {
        const deployedUrl = repo.homepage || `https://${username}.github.io/${repo.name}/`;
        const dateString = new Date(repo.updated_at).toLocaleDateString(undefined, {year:'numeric', month:'short'});
        const activityScore = Math.max(1, (repo.stargazers_count * 3) + (repo.forks_count * 2) + Math.floor(repo.size / 500));
        const polylinePoints = generatePopularityGraph(repo.stargazers_count, repo.forks_count);

        const card = document.createElement('div');
        card.className = 'repo-card';
        card.innerHTML = `
            <div>
                <div class="repo-header">
                    <a href="${deployedUrl}" class="repo-title" target="_blank">🌐 ${repo.name}</a>
                    <a href="${repo.html_url}" class="source-link" target="_blank">&lt;/&gt; Source</a>
                </div>
                <div class="repo-desc">${repo.description || 'Production build operational. Description parameter empty.'}</div>
                
                <div class="graph-container">
                    <svg class="graph-svg" viewBox="0 0 400 45">
                        <polyline fill="none" stroke="var(--accent-green)" stroke-width="2" points="${polylinePoints}" />
                    </svg>
                </div>

                <div class="stats-panel">
                    <div><div class="stat-val">★ ${repo.stargazers_count}</div><div class="stat-lbl">Stars</div></div>
                    <div><div class="stat-val">⑂ ${repo.forks_count}</div><div class="stat-lbl">Forks</div></div>
                    <div><div class="stat-val">${activityScore}</div><div class="stat-lbl">Activity Index</div></div>
                </div>
            </div>
            <div class="meta-footer">
                <span class="lang-badge">${repo.language || 'Markdown'}</span>
                <span class="date-lbl">Pushed: ${dateString}</span>
            </div>
        `;
        grid.appendChild(card);
    });
}

function applyFilters() {
    const query = document.getElementById('searchBar').value.toLowerCase();
    const lang = document.getElementById('langFilter').value;

    const filtered = allRepos.filter(repo => {
        const matchesSearch = repo.name.toLowerCase().includes(query) || 
                              (repo.description && repo.description.toLowerCase().includes(query));
        const matchesLang = lang === 'all' || (repo.language && repo.language.toLowerCase() === lang);
        return matchesSearch && matchesLang;
    });
    renderGrid(filtered);
}

initDashboard();
