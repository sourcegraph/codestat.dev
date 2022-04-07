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

First use the [explorer](https://codestat.dev/explorer) to find out what query + options you want first.

**Ultra easy way**: Tweet/message @codestat_dev, we'll chuck it into a dedicated page for you :)

**Slightly harder way**:

Just duplicate an existing dashboard, e.g.:

* `S/Golang/Net.elm`
* `S/Zulip/Dev.elm`

(the format should be `S/<Project>/<Dashboard name>`)

Look for `panel0`, `panel1`, etc. in the file and the `view model` function - it's pretty simple, just copy+paste+modify as you need, the Elm compiler will tell you if anything is wrong & will reload the page live as you edit.

Then just send your changes in a PR :)