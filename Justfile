# Typst's HTML export is still behind a feature flag.
export TYPST_FEATURES := "html"

# Build the site into _site/, then list anything in the records worth a look
build: && check
    mkdir -p _site
    typst compile --format html site.typ _site/index.html
    cp CNAME _site/

# Serve the site at localhost:3000, rebuilding and reloading on every save
watch:
    typst watch --format html site.typ _site/index.html

# List records with missing sources, likely duplicates and the like
check:
    @typst eval --target html --in site.typ --format yaml \
      '{ import "lib.typ": warnings; warnings(query(<entry>).map(m => m.value)) }'
