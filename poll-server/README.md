# Live poll server (cPanel / PHP)

Live polls (`::: {.poll}` on a slide) need a small PHP + SQLite server that students vote on from their phones. The slides call it to open and close each poll and show the results. Any web host with PHP and SQLite works; these steps are for cPanel.

Below, `https://your.server.edu/~you/poll` stands for wherever you put the `poll/` folder, and `$SECRET_KEY` stands for your own secret key.

## Package contents

```
poll/
├── index.php            student voting page (what students open)
├── script.js            checks the API every 3 s and draws the question and buttons
├── test.php             reports whether PHP has PDO and SQLite (delete it after setup)
└── pollapi/
    ├── index.php        the API and its SQLite storage: start/stop polls, record votes
    └── .htaccess.disabled   blocks downloads of the .db file once renamed to .htaccess
```

## 1. Choose a secret key

Make a long random string, for example with `openssl rand -base64 24`. In `poll/pollapi/index.php`, replace the placeholder:

```php
$SECRET_KEY = "REPLACE_WITH_YOUR_SECRET_KEY";
```

The API refuses to open or close polls while the placeholder is still there, or if the key is shorter than 16 characters. Don't commit the real key to a public repository.

## 2. Upload

1. In cPanel, open **File Manager** and go to your web root, usually `public_html`.
2. Zip the `poll/` folder on your computer, upload the zip, then right-click it and choose **Extract**. That creates the `poll/` folder.
3. Right-click `poll/pollapi` → **Change Permissions** → `755`. PHP creates the database file in this folder the first time the API runs. If testing gives "unable to open database file", try `777`.
4. Rename `poll/pollapi/.htaccess.disabled` to `.htaccess` so nobody can download the database. If your host then returns a server error, rename it back. The database's file name comes from your key, so it still can't be guessed.
5. Open `https://your.server.edu/~you/poll/test.php` to confirm PDO and SQLite are available, then delete `test.php`.

## 3. Test

- `https://your.server.edu/~you/poll/pollapi/?method=status` should return `{}` (no poll running).
- `https://your.server.edu/~you/poll/` should show "- currently no poll running -".
- Open a test question:
  `https://your.server.edu/~you/poll/pollapi/?method=start_poll&key=$SECRET_KEY&data={"question":"Test","answers":["A","B","C"],"correct_answers":[1]}`
- Reload the student page (or wait 3 s). The question and buttons should appear.
- Close it: `https://your.server.edu/~you/poll/pollapi/?method=stop_poll&key=$SECRET_KEY`
- Try `start_poll` without `key`. You should get a 403 with `{"OK":false,"error":"invalid key"}`, which shows the lock works.

Students then bookmark `https://your.server.edu/~you/poll/`. It always shows whichever question is live.

## 4. Connect your slides

In your Quarto project, turn on the plugin and the filter and give the server's address (in `_quarto.yml` or a document's front matter):

```yaml
revealjs-plugins:
  - poll
filters:
  - _extensions/paytonej/ucinci/resources/scripts/poll.lua
poll-server: https://your.server.edu/~you/poll
```

Put the key in `_secrets.json` at the project root, and add `_secrets.json` to `.gitignore`:

```json
{ "poll_key": "$SECRET_KEY" }
```

When you render, `poll.lua` writes the server and key into each slide deck that has a poll. Other formats (HTML pages, PDFs, handouts) never get the key. Because the browser sends the key to the server, anyone who has the rendered slide file can read it. Share the voting page with students, not the slide file.

## How it works

- **CORS:** `pollapi/index.php` sends `Access-Control-Allow-Origin: *`, so slides served from anywhere can call it.
- **Secret key:** `start_poll` and `stop_poll` need a `key` that matches `$SECRET_KEY`. `get_poll`, `respond` and `status`, which students' browsers call, stay open; there is nothing to protect there.
- **One vote per question per student:** tracked with a PHP session, not accounts. Fine for low-stakes polls, but a student who clears cookies can vote again.
- **Auto-expiry:** a poll left open by accident closes itself after 15 minutes.
