/*
 * Poll plugin for reveal.js / Quarto
 * Adapted from Johannes Schildgen's reveal.js-poll-plugin
 * https://github.com/jschildgen/reveal.js-poll-plugin
 *
 * Talks to a small PHP + SQLite API hosted separately from the slides
 * (see the poll/ folder deployed to cPanel). Students never see the
 * slides themselves -- they vote on a separate bare page.
 */
window.RevealPoll = (function () {

  var refresh_interval = null;
  var current_poll = null;
  var deck = null;

  // Countdown: each poll closes itself and shows the results after this many
  // seconds, or sooner if the presenter advances the slide or clicks an answer.
  // Override per poll with data-poll-time="45" (::: {.poll time=45}); 0 = no timer.
  var default_seconds = 30;
  var countdown_tick = null;

  // Filled in at render time by poll.lua:
  //   url: the poll server (poll-server: in the document or project metadata)
  //   key: "poll_key" in the project's _secrets.json; never written here.
  //        Must match $SECRET_KEY in pollapi/index.php on the server.
  var config = window.RevealPollConfig || {};
  var api_url = (config.url || "").replace(/\/+$/, "");   // no trailing slash
  var poll_key = config.key || "";

  // Where students actually go to vote -- shown as a hint on the slide.
  var student_url = api_url + "/";

  // Cache-busting helper -- some hosting layers cache identical GET
  // requests, so every call gets a unique "_" parameter appended.
  function nocache() {
    return "&_=" + Date.now();
  }

  function show_status() {
    $.get(api_url + "/pollapi/?method=status" + nocache(), function (res) {
      if (!("count" in res)) { return; } // no active poll
      $(current_poll).find("> .poll-responses").html(res.count == 0 ? "" : res.count);
    });
  }

  function start_poll() {
    if (!api_url) {
      console.warn("RevealPoll: no poll server in this deck; set poll-server: in the metadata and re-render.");
    }
    if (!poll_key) {
      console.warn("RevealPoll: no poll key in this deck; add \"poll_key\" to _secrets.json and re-render.");
    }
    // Reopening a poll (backing up and showing it again) starts from a clean box.
    $(current_poll).find("ul > li > .poll-percentage").css("width", "100%");
    $(current_poll).find("ul > li > .poll-answer-text").each(function () {
      var original = $(this).data("poll-original");
      if (original != null) { $(this).html(original).css("font-weight", ""); }
    });
    // Polls written as ::: {.poll} blocks (poll.lua) carry a data-poll-html
    // copy with math as MathML, which reads cleanly on the voting page;
    // older raw-HTML polls fall back to the slide text.
    var h1 = $(current_poll).children("h1");
    var question = h1.attr("data-poll-html") || h1.text();

    function vote_html(li) {
      return $(li).attr("data-poll-html") || $(li).children(".poll-answer-text").html();
    }

    var answers = [];
    $(current_poll).find("ul > li").each(function (i) {
      answers.push(vote_html(this));
    });

    var correct_answers = [];
    $(current_poll).find("ul > li[data-poll='correct']").each(function (i) {
      correct_answers.push(vote_html(this));
    });

    var data = { "question": question, "answers": answers, "correct_answers": correct_answers };

    $.get(api_url + "/pollapi/?method=start_poll&key=" + encodeURIComponent(poll_key)
      + "&data=" + encodeURIComponent(JSON.stringify(data)) + nocache(), function (res) { });

    refresh_interval = window.setInterval(show_status, 1000);
    start_countdown(current_poll);
  }

  function poll_seconds(poll) {
    var t = parseFloat($(poll).attr("data-poll-time"));
    return isNaN(t) ? default_seconds : t;
  }

  function start_countdown(poll) {
    stop_countdown();
    var seconds = poll_seconds(poll);
    var label = $(poll).find(".poll-timer");
    var bar = $(poll).children(".poll-timer-bar");
    if (seconds <= 0) { label.text(""); bar.hide(); return; }

    var deadline = Date.now() + seconds * 1000;
    $(poll).removeClass("poll-timer-urgent");
    // Snap the bar to full, then let CSS drain it linearly over the time limit.
    bar.show().css({ transition: "none", width: "100%" });
    bar[0].offsetWidth; // force a reflow so the reset takes effect first
    bar.css({ transition: "width " + seconds + "s linear", width: "0%" });

    function tick() {
      var left = Math.max(0, Math.ceil((deadline - Date.now()) / 1000));
      label.text(left + " s");
      $(poll).toggleClass("poll-timer-urgent", left <= 5);
      if (left <= 0) { stop_countdown(); reveal_answer(poll); }
    }
    tick();
    countdown_tick = window.setInterval(tick, 200);
  }

  function stop_countdown() {
    if (countdown_tick != null) { clearInterval(countdown_tick); countdown_tick = null; }
  }

  // Close the poll and show results by stepping onto the hidden .poll-reveal
  // fragment, so the deck's fragment state matches what the presenter sees and
  // the next key press moves on rather than "revealing" a second time.
  function reveal_answer(poll) {
    var step = $(poll).find(".poll-reveal")[0];
    var slide = deck && deck.getCurrentSlide();
    if (step && slide && slide.contains(step) && !step.classList.contains("visible")) {
      deck.navigateFragment(parseInt(step.getAttribute("data-fragment-index"), 10));
    } else {
      stop_poll();
    }
  }

  function stop_poll() {
    if (current_poll == null) { return; }
    var poll = current_poll;
    current_poll = null;
    clearInterval(refresh_interval);
    stop_countdown();
    $(poll).find(".poll-timer").text("closed");
    $(poll).children(".poll-timer-bar").css({ transition: "none", width: "0%" });
    $(poll).removeClass("poll-timer-urgent");
    $(poll).find("ul > li > .poll-percentage").css("width", "0%");

    $.get(api_url + "/pollapi/?method=stop_poll&key=" + encodeURIComponent(poll_key) + nocache(), function (res) {
      var total = 0;
      for (var i in res.answers) { total += res.answers[i]; }

      $(poll).find("ul > li > .poll-percentage").each(function (i) {
        var percentage = ("" + i in res.answers) ? 100 * res.answers[i] / total : 0;
        $(this).css("width", percentage + "%");
      });

      $(poll).find("ul > li[data-poll='correct'] > .poll-answer-text").css("font-weight", "bold");
      $(poll).find("ul > li[data-poll='correct'] > .poll-answer-text").each(function (i) {
        if ($(this).data("poll-original") == null) { $(this).data("poll-original", $(this).html()); }
        $(this).html("&rightarrow; " + $(this).html() + " &leftarrow;");
      });
    });
  }

  return {
    id: "poll",
    init: function (reveal) {
      deck = reveal;
      if (window.location.search.match(/print-pdf/gi)) {
        return; // don't show poll widgets in print/PDF export
      }

      // Each poll gets a hidden fragment of its own, one step after the poll
      // box. Advancing onto it (presenter's "next", the timer running out, or a
      // click on an answer) closes the poll and shows the results.
      $(".poll").not(":has(>.poll-reveal)").each(function () {
        var step = $('<span class="fragment poll-reveal" aria-hidden="true"></span>');
        var idx = this.getAttribute("data-fragment-index");
        if (idx != null) {
          // Explicitly ordered poll: make room for the reveal step right after it.
          idx = parseInt(idx, 10);
          $(this).closest("section").find(".fragment[data-fragment-index]").each(function () {
            var j = parseInt(this.getAttribute("data-fragment-index"), 10);
            if (j > idx) { this.setAttribute("data-fragment-index", j + 1); }
          });
          step.attr("data-fragment-index", idx + 1);
        }
        $(this).append(step);
      });

      deck.addEventListener("fragmentshown", function (event) {
        // Jumping several steps at once (e.g. reloading mid-deck) shows the poll
        // and its reveal step together; handle them in document order.
        $(event.fragments || [event.fragment]).each(function () {
          if ($(this).hasClass("poll")) {
            if (current_poll && current_poll !== this) { stop_poll(); }
            current_poll = this;
            start_poll();
          } else if ($(this).hasClass("poll-reveal")) {
            if (current_poll === $(this).closest(".poll")[0]) { stop_poll(); }
          }
        });
      });

      deck.addEventListener("fragmenthidden", function (event) {
        // Backing up past a running poll closes it.
        $(event.fragments || [event.fragment]).each(function () {
          if ($(this).hasClass("poll") && current_poll === this) { stop_poll(); }
        });
      });

      deck.addEventListener("slidechanged", function (event) {
        // Leaving the slide by any route (overview, jump, link) closes the poll.
        if (current_poll && !event.currentSlide.contains(current_poll)) { stop_poll(); }
      });

      // Mark each answer once with .poll-ready. (The old test, "has no <span>
      // child", skipped answers containing math, since KaTeX output is a span.)
      var fresh = $(".poll > ul > li").not(".poll-ready");

      fresh.click(function () {
        var poll = $(this).closest(".poll")[0];
        if (current_poll === poll) { reveal_answer(poll); }
      });

      $(".poll > h2").html(
        'Vote at <a href="' + student_url + '" style="color:inherit;">' + student_url + "</a>"
        + '<span class="poll-timer"></span>'
      );

      $(".poll").not(":has(>.poll-timer-bar)").each(function () {
        $(this).prepend('<div class="poll-timer-bar"></div>');
      });

      fresh.each(function (i) {
        this.innerHTML = '<span class="poll-percentage"></span>'
          + '<span class="poll-answer-text">' + this.innerHTML + "</span>";
        this.classList.add("poll-ready");
      });

      $(".poll").not(":has(>.poll-responses)").each(function (i) {
        $(this).append('<span class="poll-responses"></span>');
      });

      $(".poll").show();
    }
  };

})();
