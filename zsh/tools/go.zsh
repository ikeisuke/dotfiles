# Go
if command -v go >/dev/null 2>&1; then
  path_append "$(go env GOPATH)/bin"
fi
