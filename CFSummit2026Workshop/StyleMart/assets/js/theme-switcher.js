// assets/js/theme-switcher.js
// Theme configuration and switcher

const THEMES = [
  { id: 'default', name: 'Warm Editorial', description: 'Classic warm tones' },
  { id: 'blue', name: 'Modern Blue', description: 'Clean and professional' },
  { id: 'dark', name: 'Dark Mode', description: 'Easy on the eyes' },
  { id: 'purple', name: 'Purple Luxe', description: 'Elegant and bold' },
  { id: 'green', name: 'Green Nature', description: 'Fresh and calm' },
  { id: 'slate', name: 'Slate Professional', description: 'Sleek and modern' }
];

const STORAGE_KEY = 'stylemart.theme';

export function initThemeSwitcher() {
  const currentTheme = getCurrentTheme();
  applyTheme(currentTheme);

  // Create theme switcher UI if it doesn't exist
  createThemeSwitcher();
}

export function getCurrentTheme() {
  try {
    return localStorage.getItem(STORAGE_KEY) || 'default';
  } catch (e) {
    return 'default';
  }
}

export function setTheme(themeId) {
  if (!THEMES.find(t => t.id === themeId)) {
    console.warn(`Theme "${themeId}" not found, using default`);
    themeId = 'default';
  }

  applyTheme(themeId);

  try {
    localStorage.setItem(STORAGE_KEY, themeId);
  } catch (e) {
    console.warn('Could not save theme preference');
  }
}

function applyTheme(themeId) {
  document.documentElement.setAttribute('data-theme', themeId);
}

function createThemeSwitcher() {
  // Check if switcher already exists
  if (document.querySelector('[data-theme-switcher]')) return;

  const currentTheme = getCurrentTheme();

  // Create dropdown in header actions
  const headerActions = document.querySelector('.site-header__actions');
  if (!headerActions) return;

  const dropdown = document.createElement('div');
  dropdown.className = 'theme-switcher';
  dropdown.setAttribute('data-theme-switcher', '');

  const button = document.createElement('button');
  button.className = 'icon-btn';
  button.setAttribute('aria-label', 'Switch theme');
  button.setAttribute('title', 'Switch theme');
  button.innerHTML = '🎨';

  const menu = document.createElement('div');
  menu.className = 'theme-switcher__menu';
  menu.style.display = 'none';

  THEMES.forEach(theme => {
    const item = document.createElement('button');
    item.className = 'theme-switcher__item';
    if (theme.id === currentTheme) {
      item.classList.add('theme-switcher__item--active');
    }
    item.setAttribute('data-theme-id', theme.id);
    item.innerHTML = `
      <span class="theme-switcher__name">${theme.name}</span>
      <span class="theme-switcher__desc">${theme.description}</span>
    `;

    item.addEventListener('click', () => {
      setTheme(theme.id);
      // Update active state
      menu.querySelectorAll('.theme-switcher__item').forEach(i => {
        i.classList.remove('theme-switcher__item--active');
      });
      item.classList.add('theme-switcher__item--active');
      menu.style.display = 'none';
    });

    menu.appendChild(item);
  });

  button.addEventListener('click', (e) => {
    e.stopPropagation();
    const isOpen = menu.style.display === 'block';
    menu.style.display = isOpen ? 'none' : 'block';
  });

  // Close menu when clicking outside
  document.addEventListener('click', (e) => {
    if (!dropdown.contains(e.target)) {
      menu.style.display = 'none';
    }
  });

  dropdown.appendChild(button);
  dropdown.appendChild(menu);
  headerActions.insertBefore(dropdown, headerActions.firstChild);
}
