// Portfolio dashboard interactivity
(function () {
  // Footer year
  document.getElementById('year').textContent = new Date().getFullYear();

  // Mobile sidebar toggle
  var toggle = document.getElementById('menuToggle');
  var sidebar = document.getElementById('sidebar');
  toggle.addEventListener('click', function () {
    sidebar.classList.toggle('open');
  });

  // Active nav highlighting on scroll
  var links = Array.prototype.slice.call(document.querySelectorAll('.side-nav a'));
  var sections = links.map(function (a) { return document.querySelector(a.getAttribute('href')); });

  function onScroll() {
    var current = sections[0];
    for (var i = 0; i < sections.length; i++) {
      if (sections[i] && sections[i].getBoundingClientRect().top <= 120) current = sections[i];
    }
    links.forEach(function (a) {
      a.classList.toggle('active', current && a.getAttribute('href') === '#' + current.id);
    });
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  // Close sidebar after nav click on mobile
  links.forEach(function (a) {
    a.addEventListener('click', function () { sidebar.classList.remove('open'); });
  });

  var profileForm = document.getElementById('profileForm');
  var shareResult = document.getElementById('shareResult');
  var linkedinInput = profileForm.elements.linkedin;

  function safeLinkedInUrl(value) {
    if (!value) return '';
    try {
      var url = new URL(value);
      if (url.protocol !== 'https:' || !/(^|\.)linkedin\.com$/i.test(url.hostname)) return null;
      return url.href;
    } catch (error) {
      return null;
    }
  }

  function encodeProfile(profile) {
    var bytes = new TextEncoder().encode(JSON.stringify(profile));
    var binary = '';
    for (var i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
  }

  function decodeProfile(encoded) {
    try {
      var base64 = encoded.replace(/-/g, '+').replace(/_/g, '/');
      base64 += '='.repeat((4 - base64.length % 4) % 4);
      var binary = atob(base64);
      var bytes = Uint8Array.from(binary, function (character) { return character.charCodeAt(0); });
      var profile = JSON.parse(new TextDecoder().decode(bytes));
      return profile && typeof profile.name === 'string' && typeof profile.headline === 'string' ? profile : null;
    } catch (error) {
      return null;
    }
  }

  function escapeHtml(value) {
    return String(value || '').replace(/[&<>"']/g, function (character) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[character];
    });
  }

  function renderSharedProfile(profile) {
    var linkedin = safeLinkedInUrl(profile.linkedin || '');
    var skills = Array.isArray(profile.skills) ? profile.skills : [];
    var experience = Array.isArray(profile.experience) ? profile.experience : [];
    var education = Array.isArray(profile.education) ? profile.education : [];
    var linkedinLink = linkedin
      ? '<a class="linkedin-link" href="' + escapeHtml(linkedin) + '" target="_blank" rel="noopener">LinkedIn profile ↗</a>'
      : '';
    var experienceItems = experience.map(function (item) {
      return '<article class="generated-item"><p class="eyebrow">' + escapeHtml(item.dates) + '</p><h3>' + escapeHtml(item.role) + '</h3><p class="generated-company">' + escapeHtml(item.company) + '</p><p>' + escapeHtml(item.summary).replace(/\n/g, '<br>') + '</p></article>';
    }).join('');
    var skillItems = skills.map(function (skill) { return '<span>' + escapeHtml(skill) + '</span>'; }).join('');
    var educationItems = education.map(function (item) { return '<li>' + escapeHtml(item) + '</li>'; }).join('');

    document.getElementById('sidebar').remove();
    document.getElementById('menuToggle').remove();
    document.body.classList.add('shared-profile');
    document.querySelector('.dashboard').innerHTML =
      '<section class="generated-profile">' +
        '<a class="back-link" href="' + escapeHtml(window.location.pathname) + '">Portfolio publisher</a>' +
        '<header class="generated-header"><p class="eyebrow">PROFESSIONAL PROFILE</p>' +
          '<h1>' + escapeHtml(profile.name) + '</h1>' +
          '<p class="generated-headline">' + escapeHtml(profile.headline) + '</p>' +
          (profile.location ? '<p class="generated-location">' + escapeHtml(profile.location) + '</p>' : '') +
          linkedinLink +
        '</header>' +
        (profile.about ? '<section class="generated-section"><h2>About</h2><p>' + escapeHtml(profile.about).replace(/\n/g, '<br>') + '</p></section>' : '') +
        (experienceItems ? '<section class="generated-section"><h2>Experience</h2>' + experienceItems + '</section>' : '') +
        (skillItems ? '<section class="generated-section"><h2>Skills</h2><div class="generated-skills">' + skillItems + '</div></section>' : '') +
        (educationItems ? '<section class="generated-section"><h2>Education</h2><ul class="generated-education">' + educationItems + '</ul></section>' : '') +
      '</section>';
    document.title = profile.name + ' | Professional Profile';
  }

  profileForm.querySelectorAll('input, textarea').forEach(function (field) {
    field.addEventListener('input', function () { field.setCustomValidity(''); });
  });

  profileForm.addEventListener('submit', function (event) {
    event.preventDefault();
    var linkedin = safeLinkedInUrl(linkedinInput.value.trim());
    if (linkedin === null) {
      linkedinInput.setCustomValidity('Use a secure linkedin.com profile URL.');
      linkedinInput.reportValidity();
      return;
    }

    var formData = new FormData(profileForm);
    var profile = {
      name: formData.get('name').trim(),
      headline: formData.get('headline').trim(),
      location: formData.get('location').trim(),
      linkedin: linkedin,
      about: formData.get('about').trim(),
      skills: formData.get('skills').split(',').map(function (skill) { return skill.trim(); }).filter(Boolean),
      experience: formData.get('experience').split('\n').map(function (line) {
        var parts = line.split('|').map(function (part) { return part.trim(); });
        if (!line.trim()) return null;
        return { role: parts[0] || '', company: parts[1] || '', dates: parts[2] || '', summary: parts.slice(3).join(' | ') || '' };
      }).filter(Boolean),
      education: formData.get('education').split('\n').map(function (item) { return item.trim(); }).filter(Boolean)
    };
    var shareUrl = new URL(window.location.href);
    shareUrl.search = '';
    shareUrl.searchParams.set('profile', encodeProfile(profile));
    if (shareUrl.href.length > 1800) {
      profileForm.elements.experience.setCustomValidity('Shorten the profile so the share link stays under 1,800 characters.');
      profileForm.elements.experience.reportValidity();
      return;
    }
    profileForm.elements.experience.setCustomValidity('');
    document.getElementById('shareUrl').value = shareUrl.href;
    document.getElementById('openShareUrl').href = shareUrl.href;
    shareResult.hidden = false;
  });

  document.getElementById('clearProfile').addEventListener('click', function () {
    profileForm.reset();
    shareResult.hidden = true;
    profileForm.querySelectorAll('input, textarea').forEach(function (field) { field.setCustomValidity(''); });
  });

  document.getElementById('copyShareUrl').addEventListener('click', function () {
    var shareUrl = document.getElementById('shareUrl');
    shareUrl.select();
    var copyButton = document.getElementById('copyShareUrl');
    if (!navigator.clipboard || !navigator.clipboard.writeText) {
      document.execCommand('copy');
      copyButton.textContent = 'Copied';
      return;
    }
    navigator.clipboard.writeText(shareUrl.value).then(function () {
      copyButton.textContent = 'Copied';
    }).catch(function () {
      document.execCommand('copy');
      copyButton.textContent = 'Copied';
    });
  });

  var sharedProfile = new URLSearchParams(window.location.search).get('profile');
  if (sharedProfile) {
    var decodedProfile = decodeProfile(sharedProfile);
    if (decodedProfile) renderSharedProfile(decodedProfile);
  }
})();
