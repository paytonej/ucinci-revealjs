<script>
// UCinci Quarto Reveal.js Navigation & Logo Script

// Slides marked {.before-title} (for example an instructor's setup slide) are
// moved ahead of the title slide, so the deck opens on them. The title slide is
// written by the template, so this can only be done once the page is built.
// Reveal may already have read the slide order by the time this runs, so it is
// told to re-read it (sync) once it is ready.
(function () {
  const title = document.getElementById('title-slide');
  const early = document.querySelectorAll('.reveal .slides > section.before-title');
  if (!title || !early.length || /print-pdf/.test(location.search)) return;
  early.forEach(s => title.parentNode.insertBefore(s, title));
  const resync = () => {
    Reveal.sync();
    // Open on the first slide unless the address names another one (a reload mid-lecture).
    if (!location.hash || location.hash === '#/' || location.hash === '#/title-slide') Reveal.slide(0);
  };
  if (Reveal.isReady()) resync(); else Reveal.on('ready', resync);
})();

Reveal.on('slidechanged', event => {
  const slide = event.currentSlide;

  // Determine nav color based on slide class
  let navColor = '#E00122';
  if (slide.classList.contains('official-uc-red-gradient')) navColor = '#ffffff';
  if (slide.classList.contains('beyond-black-gradient')) navColor = '#ffffff';
  if (slide.classList.contains('white-gradient')) navColor =  '#000000';
  if (slide.classList.contains('uc-red-flat')) navColor = "#ffffff";
  if (slide.classList.contains('uc-black-flat')) navColor = "#ffffff";
  if (slide.classList.contains('black-and-white')) navColor = "#000000";

  // Standard nav elements
  document.querySelectorAll(
    '.reveal .controls, .reveal .progress span, .reveal .slide-number'
  ).forEach(el => {
    el.style.color = navColor;
    el.style.fill = navColor;
  });

  // Hamburger menu button
  const menuBtn = document.querySelector('.reveal .slide-menu-button');
  if(menuBtn) {
    // Set color for all child SVG paths
    menuBtn.querySelectorAll('svg path, svg line').forEach(path => {
      path.setAttribute('stroke', navColor);
      path.setAttribute('fill', navColor);
    });
  }
});

// Map slide classes to nav colors
const navColors = {
  "white-gradient": "#000000",
  "official-uc-red-gradient": "#ffffff",
  "beyond-black-gradient": "#ffffff",
  "uc-red-flat": "#ffffff",
  "uc-black-flat": "#ffffff",
  "black-and-white": "#000000"
};

// Function to get nav color for a slide
function getNavColor(slide) {
  for (const cls of Object.keys(navColors)) {
    if (slide.classList.contains(cls)) return navColors[cls];
  }
  return "#E00122"; // default
}

// Update nav elements: controls, progress, slide numbers
function updateNavElements(slide) {
  const color = getNavColor(slide);
  document.querySelectorAll('.reveal .controls, .reveal .progress span, .reveal .slide-number')
    .forEach(el => {
      el.style.color = color;
      el.style.fill = color;
    });
}

// Update hamburger menu
function updateMenuIcon(slide) {
  const menuBtn = document.querySelector('.slide-menu-button');
  if (!menuBtn) return;

  const color = getNavColor(slide);
  const size = 32; // px

  // Remove old SVG
  const oldSvg = menuBtn.querySelector('svg');
  if (oldSvg) oldSvg.remove();

  // Create new SVG
  const svgNS = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(svgNS, "svg");
  svg.setAttribute("width", size);
  svg.setAttribute("height", size);
  svg.setAttribute("viewBox", "0 0 16 16");
  svg.setAttribute("fill", color);
  svg.setAttribute("class", "bi bi-list");

  const path = document.createElementNS(svgNS, "path");
  path.setAttribute("fill-rule", "evenodd");
  path.setAttribute("d", "M2.5 12a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5z");
  svg.appendChild(path);

  menuBtn.appendChild(svg);
}

// Main function to update everything
function updateSlideUI(slide) {
  if (!slide) return;
  updateNavElements(slide);
  updateMenuIcon(slide);
  updateLogoColor(slide);
}

// Initial load
document.addEventListener('DOMContentLoaded', () => {
  updateSlideUI(Reveal.getCurrentSlide());
  updateLogoColor(Reveal.getCurrentSlide());
});

function updateLogoColor(slide) {
  const logo = document.querySelector('.reveal.has-logo .slide-logo svg');
  if (!logo) return;

  let logoColor = '#E00122'; // default

  if (slide.classList.contains('official-uc-red-gradient')) logoColor = '#ffffff';
  if (slide.classList.contains('beyond-black-gradient')) logoColor = '#ffffff';
  if (slide.classList.contains('uc-red-flat')) logoColor = '#ffffff';
  if (slide.classList.contains('uc-black-flat')) logoColor = '#ffffff'
  if (slide.classList.contains('black-and-white')) logoColor = '#000000'

  // Change the fill for all paths inside the SVG
  logo.querySelectorAll('*').forEach(el => {
    el.setAttribute('fill', logoColor);
  });
}

Reveal.on('slidechanged', function(event) {
  const slide = event.currentSlide;
  updateLogoColor(slide);
});

function updateTitleSlideLogo() {
  const logo = document.querySelector('.title-slide-logo');
  if (!logo) return;

  // The title slide isn't always first (see {.before-title} above).
  const slide = Reveal.getCurrentSlide();
  if (slide && slide.id === 'title-slide') {
    logo.style.display = 'block';
  } else {
    logo.style.display = 'none';
  }
}

// On slide change
Reveal.on('slidechanged', updateTitleSlideLogo);

/* On initial load */
document.addEventListener('DOMContentLoaded', updateTitleSlideLogo);

// Animate .collapse-out fragments (see revealjs-supplement.css) so content
// below them slides up/down instead of jumping. CSS can't transition
// height to/from auto, so pin the start height inline, then release it.
function collapseOutFragments(fragments) {
  return fragments.filter(el => el.classList.contains('collapse-out'));
}

Reveal.on('fragmentshown', event => {
  collapseOutFragments(event.fragments).forEach(el => {
    // .visible (height: 0) may already be applied and flushed by the time
    // this fires, so jump back to full height with height transitions
    // off (keeping the opacity fade running), then release to 0.
    el.style.transitionProperty = 'opacity, visibility';
    el.style.height = el.scrollHeight + 'px';
    el.offsetHeight; // force reflow so the transition has a start value
    el.style.transitionProperty = '';
    el.style.height = '';
  });
});

Reveal.on('fragmenthidden', event => {
  collapseOutFragments(event.fragments).forEach(el => {
    el.style.overflow = 'hidden';
    el.style.height = '0px';
    const target = el.scrollHeight;
    el.offsetHeight;
    el.style.height = target + 'px';
    el.addEventListener('transitionend', function done(e) {
      if (e.propertyName !== 'height') return;
      el.style.height = '';
      el.style.overflow = '';
      el.removeEventListener('transitionend', done);
    });
  });
});
</script>