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
})();
