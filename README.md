# [codestat.dev](https://codestat.dev): stats from 2m+ OSS repositories

Follow [@codestat_dev](https://twitter.com/codestat_dev) on Twitter so you don't miss any new code stats!

## 🌳 Elm

codestat.dev is written in the [Elm language](https://elm-lang.org/) and built with [elm-spa](https://elm-spa.dev). Before diving in, check out:

* [elm-spa.dev](https://elm-spa.dev)
* [Elm guide](https://guide.elm-lang.org/)

Don't be afraid to just jump in and try changing things, though! The Elm compiler is really good about telling you if anything is wrong.

## Developing

Install Elm and elm-spa (may require latest LTS version of [Node.js](https://nodejs.org/)):

```bash
npm install -g elm elm-spa
```

### running locally

```bash
elm-spa server  # starts this app at http:/localhost:1234
```

## Adding a new dashboard

It's pretty simple! Duplicate `S/Zulip.elm` (which corresponds to `/s/zulip`, be sure to put yours under a relevant URL under `/s/` - projects are `/s/project` while one-off stats are `/s/project/stat-name` under the project they're relevant to).

Look in the file for `panel0` - this is where you can modify the panels that appear on the page, their queries, etc.
