(function () {
  function startVideo(video) {
    if (video.defaultMuted) video.muted = true;
    var playback = video.play();
    if (playback && playback.catch) {
      playback.catch(function (error) {
        video.controls = true;
        if (error.name !== 'NotAllowedError' && error.name !== 'AbortError') {
          console.warn('Unable to autoplay video:', video.currentSrc, error);
        }
      });
    }
  }

  function initializeVideos() {
    var videos = document.querySelectorAll('.video-embed video[autoplay]');
    if (!('IntersectionObserver' in window)) {
      videos.forEach(startVideo);
      return;
    }

    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        // Try once on entry; later user pauses must remain paused.
        observer.unobserve(entry.target);
        startVideo(entry.target);
      });
    });
    videos.forEach(function (video) { observer.observe(video); });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeVideos);
  } else {
    initializeVideos();
  }
})();
